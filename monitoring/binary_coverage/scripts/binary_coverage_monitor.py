#!/usr/bin/env python3
"""Collect binary coverage job results from openQA into InfluxDB line protocol.

Runs from telegraf inputs.exec. stdout must stay pure line protocol; all
diagnostics go to stderr.
"""

import argparse
import calendar
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "binary-coverage-monitor"
FINAL_STATES = ("done",)
INELIGIBLE_RESULTS = (
    "obsoleted",
    "user_cancelled",
    "user_restarted",
    "parallel_restarted",
    "skipped",
)
RUNNING_STATES = ("scheduled", "assigned", "setup", "running", "uploading")
OK_MODULE_RESULTS = ("passed", "softfailed")
JOBS_LIMIT = 500

DEFAULTS = {
    "instances": [{"name": "o3", "url": "https://openqa.opensuse.org"}],
    "test": "binary_coverage_ultimate",
    "distri": "opensuse",
    "version": "Tumbleweed",
    "group_id": 145,
    "lookback_days": 45,
    "stale_hours": 36,
    "cache_dir": "/var/cache/binary_coverage",
    "http_timeout": 60,
    "http_retries": 2,
}

STATUS_OK = 0
STATUS_NEW_FAILURES = 1
STATUS_NO_REPORT = 2
STATUS_STALE = 3
STATUS_COLLECTOR_ERROR = 4

STATUS_TEXT = {
    STATUS_OK: "OK",
    STATUS_NEW_FAILURES: "NEW_FAILURES",
    STATUS_NO_REPORT: "NO_REPORT",
    STATUS_STALE: "STALE",
    STATUS_COLLECTOR_ERROR: "COLLECTOR_ERROR",
}


class FetchError(Exception):
    pass


def load_config(path):
    with open(path) as f:
        cfg = json.load(f)
    merged = dict(DEFAULTS)
    merged.update(cfg)
    return merged


def http_get(url, timeout=60, retries=2):
    last = None
    for attempt in range(retries + 1):
        # o3's bot protection challenges requests without an Accept header
        req = urllib.request.Request(
            url, headers={"User-Agent": USER_AGENT, "Accept": "*/*"}
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                raise FetchError("%s: HTTP 404" % url)
            last = exc
        except Exception as exc:  # network errors, timeouts
            last = exc
        if attempt < retries:
            time.sleep(1 + attempt)
    raise FetchError("%s: %s" % (url, last))


def parse_openqa_time(value):
    return calendar.timegm(time.strptime(value, "%Y-%m-%dT%H:%M:%S"))


def _first(pattern, text):
    m = re.search(pattern, text)
    return m.group(1) if m else None


def parse_aggregate_html(text):
    """Parse the funkoverage aggregate report, one line at a time.

    Returns None when any summary value is missing so callers can treat the
    report as unusable.
    """
    if "#" not in text and "Total Functions" not in text:
        return None
    total_functions = None
    total_executed = None
    coverage_pct = None
    images = []
    in_tbody = False
    row = None

    for line in text.splitlines():
        if not total_functions:
            value = _first(r"<strong>Total Functions:</strong>\s*(\d+)", line)
            if value:
                total_functions = int(value)
                continue
        if total_executed is None:
            value = _first(r"<strong>Total Executed:</strong>\s*(\d+)", line)
            if value:
                total_executed = int(value)
                continue
        if coverage_pct is None:
            value = _first(r"<strong>Average Coverage:</strong>\s*([\d.]+)%", line)
            if value:
                coverage_pct = float(value)
                continue

        if "<tbody>" in line:
            in_tbody = True
            continue
        if "</tbody>" in line:
            in_tbody = False
            continue
        if not in_tbody:
            continue

        if "<tr>" in line:
            row = {"name": None, "total": None, "called": None, "pct": None}
            continue
        if row is None:
            continue

        for td in re.findall(r"<td>([^<]+)</td>", line):
            td = html.unescape(td).strip()
            if row["name"] is None:
                row["name"] = td
            elif row["total"] is None:
                row["total"] = int(td)
            elif row["called"] is None:
                row["called"] = int(td)

        pct = _first(r'bar-label">([\d.]+)%<', line)
        if pct is not None:
            row["pct"] = float(pct)

        if "</tr>" in line:
            if (
                row["name"]
                and row["total"] is not None
                and row["called"] is not None
                and row["pct"] is not None
            ):
                images.append(
                    {
                        "image": row["name"],
                        "total_functions": row["total"],
                        "called_functions": row["called"],
                        "coverage_pct": row["pct"],
                    }
                )
            row = None

    if total_functions is None or total_executed is None or coverage_pct is None:
        return None
    return {
        "total_functions": total_functions,
        "total_executed": total_executed,
        "coverage_pct": coverage_pct,
        "images": images,
    }


def _testresults(details):
    if not details:
        return []
    if "job" in details:
        return details["job"].get("testresults", [])
    return details.get("testresults", [])


def _summary(aggregate):
    """Keep the totals and the number of images, not the per-image rows."""
    if aggregate is None:
        return None
    return {
        "total_functions": aggregate["total_functions"],
        "total_executed": aggregate["total_executed"],
        "coverage_pct": aggregate["coverage_pct"],
        "images": len(aggregate["images"]),
    }


def classify_job(job, details, aggregate, test_git_hash=None):
    results = {}
    for tr in _testresults(details):
        results[tr.get("name")] = tr.get("result")
    failed_set = sorted(name for name, res in results.items() if res == "failed")
    modules_passed = sum(1 for res in results.values() if res in OK_MODULE_RESULTS)
    modules_failed = sum(1 for res in results.values() if res == "failed")
    modules_ok = (
        results.get("coverage_setup") in OK_MODULE_RESULTS
        and results.get("coverage_report") in OK_MODULE_RESULTS
    )
    report_ok = (
        modules_ok and aggregate is not None and aggregate.get("total_functions", 0) > 0
    )

    settings = job.get("settings", {})
    build = settings.get("BUILD", "")
    snapshot = None
    iso = settings.get("ISO", "")
    if iso:
        snapshot = _first(r"Snapshot(\d{8})", iso)
    if not snapshot and build[:8].isdigit():
        snapshot = build[:8]

    t_finished = job.get("t_finished")
    return {
        "job_id": int(job.get("id", 0)),
        "report_ok": 1 if report_ok else 0,
        "aggregate_missing": bool(modules_ok and not report_ok),
        "failed_set": failed_set,
        "modules_passed": modules_passed,
        "modules_failed": modules_failed,
        "snapshot": snapshot or "",
        "build": build,
        "t_finished": t_finished,
        "t_finished_epoch": parse_openqa_time(t_finished) if t_finished else 0,
        "aggregate": _summary(aggregate),
        "test_git_hash": test_git_hash or "",
    }


def is_eligible(job):
    return (
        job.get("state") in FINAL_STATES
        and job.get("clone_id") is None
        and job.get("result") not in INELIGIBLE_RESULTS
    )


def compute_new_failures(classified_jobs):
    """Annotate each job with failures not present in the last good run.

    A run without a report (timeout, incomplete) stops early, so its failed
    modules are not a reliable baseline.
    """
    baseline = None
    for job in classified_jobs:
        if baseline is None:
            new = []
        else:
            new = sorted(set(job["failed_set"]) - set(baseline["failed_set"]))
        job["new_failures"] = new
        if job.get("report_ok"):
            baseline = job


def compute_status(eligible_jobs, running_job, now, cfg, error=None):
    status = {
        "status": STATUS_OK,
        "last_job_id": 0,
        "last_job_result": "",
        "last_ok_job_id": 0,
        "last_ok_finished": None,
        "hours_since_last_ok": 0.0,
        "new_failures": [],
        "running": 1 if running_job else 0,
        "running_job_id": int(running_job.get("id", 0)) if running_job else 0,
    }
    if error:
        status["status"] = STATUS_COLLECTOR_ERROR
        return status

    report_ok_jobs = [j for j in eligible_jobs if j.get("report_ok")]
    if report_ok_jobs:
        last_ok = report_ok_jobs[-1]
        status["last_ok_job_id"] = int(last_ok["job_id"])
        status["last_ok_finished"] = last_ok["t_finished_epoch"]
        status["hours_since_last_ok"] = round(
            (now - last_ok["t_finished_epoch"]) / 3600.0, 2
        )

    if not eligible_jobs:
        status["status"] = STATUS_STALE
        return status

    last = eligible_jobs[-1]
    status["last_job_id"] = int(last["job_id"])
    status["last_job_result"] = last.get("result", "")
    status["new_failures"] = last.get("new_failures", [])

    if not last.get("report_ok"):
        status["status"] = STATUS_NO_REPORT
        return status
    if status["new_failures"]:
        status["status"] = STATUS_NEW_FAILURES
        return status
    if not report_ok_jobs or status["hours_since_last_ok"] > cfg.get("stale_hours", 36):
        status["status"] = STATUS_STALE
        return status
    status["status"] = STATUS_OK
    return status


def escape_tag(value):
    return str(value).replace(",", "\\,").replace(" ", "\\ ").replace("=", "\\=")


def escape_field_str(value):
    return '"%s"' % str(value).replace("\\", "\\\\").replace('"', '\\"')


def format_line(measurement, tags, fields, ts_ns=None):
    parts = [escape_tag(measurement)]
    for key in sorted(tags):
        parts.append("%s=%s" % (escape_tag(key), escape_tag(tags[key])))
    rendered = []
    for key in sorted(fields):
        value = fields[key]
        if isinstance(value, bool):
            rendered.append("%s=%di" % (escape_tag(key), 1 if value else 0))
        elif isinstance(value, int):
            rendered.append("%s=%di" % (escape_tag(key), value))
        elif isinstance(value, float):
            rendered.append("%s=%s" % (escape_tag(key), repr(value)))
        else:
            rendered.append("%s=%s" % (escape_tag(key), escape_field_str(value)))
    line = ",".join(parts) + " " + ",".join(rendered)
    if ts_ns is not None:
        line += " %d" % int(ts_ns)
    return line


def _job_url(instance, path):
    return instance["url"].rstrip("/") + path


def fetch_jobs(instance, cfg, fetch):
    params = [
        ("distri", cfg["distri"]),
        ("version", cfg["version"]),
        ("test", cfg["test"]),
        ("limit", JOBS_LIMIT),
        ("groupid", int(cfg["group_id"])),
    ]
    query = urllib.parse.urlencode(params)
    data = json.loads(
        fetch(_job_url(instance, "/api/v1/jobs?" + query)).decode("utf-8")
    )
    jobs = data.get("jobs", data)
    if len(jobs) >= JOBS_LIMIT:
        sys.stderr.write(
            "%s: got %d jobs, older runs in the window may be missing\n"
            % (instance["name"], len(jobs))
        )
    return jobs


def fetch_details(instance, job_id, fetch):
    data = json.loads(
        fetch(_job_url(instance, "/api/v1/jobs/%d/details" % job_id)).decode("utf-8")
    )
    return data.get("job", data)


def fetch_vars(instance, job_id, fetch):
    try:
        raw = fetch(_job_url(instance, "/tests/%d/file/vars.json" % job_id))
        return json.loads(raw.decode("utf-8"))
    except (FetchError, ValueError):
        return {}


def fetch_aggregate(instance, job_id, fetch):
    try:
        raw = fetch(
            _job_url(instance, "/tests/%d/file/coverage_report-aggregate.html" % job_id)
        )
        return parse_aggregate_html(raw.decode("utf-8", "replace"))
    except (FetchError, ValueError):
        return None


def cache_path(cache_dir, instance_name, job_id):
    return os.path.join(cache_dir, "%s-%d.json" % (instance_name, job_id))


def load_cached(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (IOError, OSError, ValueError):
        return None


def store_cached(path, entry):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(entry, f)
    os.rename(tmp, path)


def prune_cache(cache_dir, instance_name, threshold):
    prefix = instance_name + "-"
    for entry in os.listdir(cache_dir):
        path = os.path.join(cache_dir, entry)
        try:
            if entry.startswith(prefix) and os.path.getmtime(path) < threshold:
                os.remove(path)
        except OSError:
            pass


def classify_with_sources(instance, job, fetch):
    details = fetch_details(instance, job["id"], fetch)
    aggregate = fetch_aggregate(instance, job["id"], fetch)
    variables = fetch_vars(instance, job["id"], fetch)
    classified = classify_job(job, details, aggregate, variables.get("TEST_GIT_HASH"))
    classified["result"] = job.get("result")
    classified["state"] = job.get("state")
    return classified


def collect_instance(instance, cfg, now, fetch, write):
    name = instance["name"]
    cache_dir = cfg.get("cache_dir", DEFAULTS["cache_dir"])
    if cache_dir and not os.path.isdir(cache_dir):
        try:
            os.makedirs(cache_dir)
        except OSError:
            pass

    def cached(job_id):
        if not cache_dir:
            return None
        return load_cached(cache_path(cache_dir, name, job_id))

    def save(job_id, entry):
        if cache_dir:
            store_cached(cache_path(cache_dir, name, job_id), entry)

    jobs = fetch_jobs(instance, cfg, fetch)
    threshold = now - cfg.get("lookback_days", 45) * 86400
    if cache_dir:
        prune_cache(cache_dir, name, threshold)

    running_job = None
    for job in jobs:
        if job.get("state") in RUNNING_STATES:
            if running_job is None or int(job["id"]) > int(running_job["id"]):
                running_job = job

    eligible = []
    skipped = 0
    for job in jobs:
        if not is_eligible(job):
            continue
        finished = job.get("t_finished")
        if not finished:
            continue
        try:
            epoch = parse_openqa_time(finished)
            if epoch < threshold:
                continue
            entry = cached(int(job["id"]))
            classified = (
                classify_with_sources(instance, job, fetch) if entry is None else None
            )
        except Exception as exc:  # one bad job must not hide the others
            sys.stderr.write("%s: skipping job %s: %s\n" % (name, job.get("id"), exc))
            skipped += 1
            continue
        if entry is None:
            entry = {
                "job": {
                    "id": int(job["id"]),
                    "test": job.get("test"),
                    "state": job.get("state"),
                    "result": job.get("result"),
                    "clone_id": job.get("clone_id"),
                    "t_finished": job.get("t_finished"),
                    "settings": job.get("settings", {}),
                },
                "classified": classified,
            }
            if classified.get("aggregate_missing"):
                # Not cached, so a transient fetch failure is retried next run
                sys.stderr.write(
                    "%s: job %s passed coverage_report but its aggregate "
                    "could not be fetched or parsed\n" % (name, job["id"])
                )
            else:
                save(int(job["id"]), entry)
        else:
            classified = entry["classified"]
            if not classified.get("test_git_hash") and classified.get("report_ok"):
                classified["test_git_hash"] = fetch_vars(
                    instance, job["id"], fetch
                ).get("TEST_GIT_HASH", "")
        eligible.append(classified)

    eligible.sort(key=lambda j: (j["t_finished_epoch"], j["job_id"]))
    compute_new_failures(eligible)

    lines = []
    for job in eligible:
        tags = {"instance": name}
        fields = {
            "job_id": job["job_id"],
            "report_ok": job["report_ok"],
            "images": (job.get("aggregate") or {}).get("images", 0),
            "modules_passed": job["modules_passed"],
            "modules_failed": job["modules_failed"],
            "new_failures": len(job["new_failures"]),
            "new_failure_names": ",".join(job["new_failures"]),
            "failed_modules": ",".join(job["failed_set"]),
            "snapshot": job["snapshot"],
            "build": job["build"],
            "test_git_hash": job.get("test_git_hash", ""),
        }
        aggregate = job.get("aggregate") or {}
        if job["report_ok"]:
            fields["total_functions"] = int(aggregate["total_functions"])
            fields["total_executed"] = int(aggregate["total_executed"])
            fields["coverage_pct"] = float(aggregate["coverage_pct"])
        lines.append(
            format_line(
                "binary_coverage", tags, fields, job["t_finished_epoch"] * 10**9
            )
        )

    status = compute_status(eligible, running_job, now, cfg)
    if skipped and status["status"] == STATUS_OK:
        # A skipped job may be the newest one, so OK cannot be claimed
        status["status"] = STATUS_COLLECTOR_ERROR
    status_fields = {
        "status": status["status"],
        "status_text": STATUS_TEXT[status["status"]],
        "last_job_id": int(status["last_job_id"]),
        "last_job_result": status["last_job_result"],
        "last_ok_job_id": int(status["last_ok_job_id"]),
        "hours_since_last_ok": float(status["hours_since_last_ok"]),
        "new_failures": len(status["new_failures"]),
        "new_failure_names": ",".join(status["new_failures"]),
        "running": int(status["running"]),
        "running_job_id": int(status["running_job_id"]),
        "skipped_jobs": skipped,
    }
    lines.append(
        format_line("binary_coverage_status", {"instance": name}, status_fields)
    )

    for line in lines:
        write(line)


def collect(cfg, now=None, fetch=None, write=None):
    if now is None:
        now = int(time.time())
    if fetch is None:
        fetch = lambda url: http_get(  # noqa: E731
            url, cfg.get("http_timeout", 60), cfg.get("http_retries", 2)
        )
    if write is None:
        write = lambda line: sys.stdout.write(line + "\n")  # noqa: E731
    for instance in cfg.get("instances", []):
        try:
            collect_instance(instance, cfg, now, fetch, write)
        except Exception as exc:  # report as COLLECTOR_ERROR, never traceback
            sys.stderr.write("%s: collector error: %s\n" % (instance["name"], exc))
            status = compute_status([], None, now, cfg, error=str(exc))
            write(
                format_line(
                    "binary_coverage_status",
                    {"instance": instance["name"]},
                    {
                        "status": status["status"],
                        "status_text": STATUS_TEXT[status["status"]],
                        "last_job_id": 0,
                        "last_job_result": "",
                        "last_ok_job_id": 0,
                        "hours_since_last_ok": 0.0,
                        "new_failures": 0,
                        "new_failure_names": "",
                        "running": 0,
                        "running_job_id": 0,
                        "skipped_jobs": 0,
                    },
                )
            )


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="/etc/binary_coverage/collector.json")
    parser.add_argument("--now", type=int, default=None)
    parser.add_argument("--no-cache", action="store_true")
    args = parser.parse_args(argv)
    cfg = load_config(args.config)
    if args.no_cache:
        cfg["cache_dir"] = ""
    collect(cfg, now=args.now)
    return 0


if __name__ == "__main__":
    sys.exit(main())
