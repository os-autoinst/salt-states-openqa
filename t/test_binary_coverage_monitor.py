#!/usr/bin/env python
"""Unit tests for the binary coverage collector.

Run with pytest from the salt-states-openqa repository root.
"""

import importlib.util
import json
import os

import pytest

HERE = os.path.dirname(__file__)
DATA = os.path.join(HERE, "data", "binary_coverage")
SCRIPT = os.path.join(
    HERE,
    "..",
    "monitoring",
    "binary_coverage",
    "scripts",
    "binary_coverage_monitor.py",
)

spec = importlib.util.spec_from_file_location("binary_coverage_monitor", SCRIPT)
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)

BASE = "https://o3.test"
GROUP_ID = 145
JOBS_PATH = (
    "/api/v1/jobs?distri=opensuse&version=Tumbleweed"
    "&test=binary_coverage_ultimate&limit=500&groupid=145"
)


def load(name, binary=False):
    mode = "rb" if binary else "r"
    with open(os.path.join(DATA, name), mode) as f:
        return f.read()


def load_json(name):
    return json.loads(load(name))


class Fetcher:
    def __init__(self):
        self.routes = {}
        self.calls = []

    def add(self, path, data):
        if isinstance(data, (dict, list)):
            data = json.dumps(data).encode()
        elif isinstance(data, str):
            data = data.encode()
        self.routes[path] = data

    def add_job(self, job, details=None, variables=None, aggregate=None):
        job_id = job["id"]
        self.add("/api/v1/jobs/%d" % job_id, job)
        if details is not None:
            self.add("/api/v1/jobs/%d/details" % job_id, details)
        if variables is not None:
            self.add("/tests/%d/file/vars.json" % job_id, variables)
        if aggregate is not None:
            self.add(
                "/tests/%d/file/coverage_report-aggregate.html" % job_id, aggregate
            )

    def __call__(self, url):
        assert url.startswith(BASE), url
        path = url[len(BASE) :]
        self.calls.append(path)
        if path not in self.routes:
            raise monitor.FetchError("%s: HTTP 404" % url)
        return self.routes[path]


def make_config(tmp_path, **extra):
    cfg = dict(monitor.DEFAULTS)
    cfg["instances"] = [{"name": "o3", "url": BASE}]
    cfg["cache_dir"] = str(tmp_path)
    cfg["group_id"] = GROUP_ID
    cfg.update(extra)
    return cfg


def collect(cfg, fetch, now):
    lines = []
    monitor.collect(cfg, now=now, fetch=fetch, write=lines.append)
    return lines


def parse_lines(lines):
    """Return measurement -> list of field dicts for a simple line set."""
    out = {}
    for line in lines:
        head, rest = line.split(" ", 1)
        fields = {}
        body = rest.split(" ")[0] if " " in rest else rest
        for part in body.split(","):
            key, value = part.split("=", 1)
            if value.endswith("i") and not value.startswith('"'):
                value = int(value[:-1])
            elif value.startswith('"'):
                value = value[1:-1].replace('\\"', '"').replace("\\\\", "\\")
            else:
                try:
                    value = float(value)
                except ValueError:
                    pass
            fields[key] = value
        out.setdefault(head.split(",")[0], []).append(fields)
    return out


def status_line(lines):
    for line in lines:
        if line.startswith("binary_coverage_status"):
            return parse_lines([line])["binary_coverage_status"][0]
    raise AssertionError("no status line in %r" % lines)


def good_job(job_id=6190943, finished="2026-08-29T23:18:59"):
    job = load_json("job_%d.json" % job_id) if job_id == 6190943 else None
    if job is None:
        job = {
            "id": job_id,
            "test": "binary_coverage_ultimate",
            "state": "done",
            "result": "failed",
            "clone_id": None,
            "group_id": GROUP_ID,
            "t_finished": finished,
            "settings": {
                "BUILD": "20260829",
                "ISO": "openSUSE-Tumbleweed-DVD-x86_64-Snapshot20260828-Media.iso",
            },
        }
    job = json.loads(json.dumps(job))
    job["id"] = job_id
    job["t_finished"] = finished
    job["group_id"] = GROUP_ID
    return job


def test_parse_aggregate_good_run():
    report = monitor.parse_aggregate_html(load("aggregate_6190943.html"))
    assert report is not None
    assert report["total_functions"] == 208163
    assert report["total_executed"] == 26826
    assert report["coverage_pct"] == 12.89
    assert len(report["images"]) == 3
    assert report["images"][0] == {
        "image": "libperl.so",
        "total_functions": 1247,
        "called_functions": 0,
        "coverage_pct": 0.0,
    }


@pytest.mark.parametrize(
    "page",
    [
        '<html><body><div class="summary">\n<ul>\n</body></html>',
        "<tbody>\n<tr>\n<td>libfoo.so</td>\n<td>10</td>\n<td>1</td>\n"
        '<span class="bar-label">10.0%</span>\n</tr>\n</tbody>\n',
    ],
)
def test_parse_aggregate_rejects_incomplete(page):
    assert monitor.parse_aggregate_html(page) is None


def test_parse_aggregate_unescapes_image_names():
    html = (
        "<li><strong>Total Functions:</strong> 3</li>\n"
        "<li><strong>Total Executed:</strong> 1</li>\n"
        "<li><strong>Average Coverage:</strong> 33.3%</li>\n"
        "<tbody>\n<tr>\n<td>a&amp;b, c</td>\n<td>3</td>\n<td>1</td>\n"
        '<span class="bar-label">33.3%</span>\n</tr>\n</tbody>\n'
    )
    report = monitor.parse_aggregate_html(html)
    assert report["images"][0]["image"] == "a&b, c"


def test_parse_openqa_time():
    assert monitor.parse_openqa_time("2026-08-29T23:18:59") == 1788045539


def test_line_protocol_formatting_and_escaping():
    line = monitor.format_line(
        "binary_coverage",
        {"instance": "o3", "image": "a b,c=d"},
        {"job_id": 7, "coverage_pct": 12.5, "text": 'say "hi"'},
        1788045539 * 10**9,
    )
    assert line == (
        "binary_coverage,image=a\\ b\\,c\\=d,instance=o3 "
        'coverage_pct=12.5,job_id=7i,text="say \\"hi\\"" '
        "1788045539000000000"
    )


def test_classify_job_report_ok_and_snapshot():
    job = load_json("job_6190943.json")
    details = load_json("details_6190943.json")
    aggregate = monitor.parse_aggregate_html(load("aggregate_6190943.html"))
    classified = monitor.classify_job(job, details, aggregate, "abc123")
    assert classified["report_ok"] == 1
    assert classified["snapshot"] == "20260828"
    assert classified["modules_failed"] == 10
    assert "ping" in classified["failed_set"]
    assert classified["test_git_hash"] == "abc123"


def test_classify_job_without_report():
    job = good_job(6237424)
    job["result"] = "incomplete"
    classified = monitor.classify_job(job, {"job": {"testresults": []}}, None)
    assert classified["report_ok"] == 0


def test_classify_job_marks_failed_setup_as_not_started():
    job = good_job(6338558)
    job["result"] = "failed"
    details = {
        "job": {
            "testresults": [
                {"name": "system_prepare", "result": "passed"},
                {"name": "coverage_setup", "result": "failed"},
                {"name": "curl_https", "result": "skipped"},
            ]
        }
    }
    classified = monitor.classify_job(job, details, None)
    assert classified["started"] == 0
    assert classified["report_ok"] == 0


def test_is_eligible_excludes_obsoleted_cloned_running():
    assert monitor.is_eligible(good_job())
    for key, value in (
        ("result", "obsoleted"),
        ("state", "running"),
        ("clone_id", 6190944),
    ):
        job = good_job()
        job[key] = value
        assert not monitor.is_eligible(job)


def test_compute_new_failures():
    first = {"failed_set": ["a", "b"], "report_ok": 1}
    second = {"failed_set": ["b", "c"], "report_ok": 1}
    third = {"failed_set": ["b", "c"], "report_ok": 1}
    jobs = [first, second, third]
    monitor.compute_new_failures(jobs)
    assert first["new_failures"] == []
    assert second["new_failures"] == ["c"]
    assert third["new_failures"] == []


def classified(job_id, failed, report_ok=1, epoch=1788045539, git="abc"):
    return {
        "job_id": job_id,
        "report_ok": report_ok,
        "failed_set": failed,
        "new_failures": [],
        "modules_passed": 1,
        "modules_failed": len(failed),
        "snapshot": "20260828",
        "build": "20260828",
        "t_finished": "2026-08-29T23:18:59",
        "t_finished_epoch": epoch,
        "aggregate": {
            "total_functions": 1,
            "total_executed": 1,
            "coverage_pct": 100.0,
            "images": [],
        },
        "test_git_hash": git,
    }


def test_new_failures_ignore_a_run_that_never_started():
    good = {"failed_set": ["a"], "report_ok": 1, "started": 1}
    aborted = {"failed_set": ["coverage_setup"], "report_ok": 0, "started": 0}
    next_good = {"failed_set": ["a"], "report_ok": 1, "started": 1}
    monitor.compute_new_failures([good, aborted, next_good])
    assert aborted["new_failures"] == []
    assert next_good["new_failures"] == []


def test_status_ok():
    jobs = [classified(1, []), classified(2, [])]
    status = monitor.compute_status(jobs, None, 1788045539 + 3600, {})
    assert status["status"] == monitor.STATUS_OK


def test_status_same_failures_is_ok():
    first = classified(1, ["a"])
    second = classified(2, ["a"], epoch=1788045539 + 60)
    monitor.compute_new_failures([first, second])
    status = monitor.compute_status([first, second], None, 1788045539 + 120, {})
    assert status["status"] == monitor.STATUS_OK
    assert status["new_failures"] == []


def test_status_new_failures_reported():
    first = classified(1, [])
    second = classified(2, ["b"], epoch=1788045539 + 60)
    monitor.compute_new_failures([first, second])
    status = monitor.compute_status([first, second], None, 1788045539 + 120, {})
    assert status["status"] == monitor.STATUS_NEW_FAILURES
    assert status["new_failures"] == ["b"]


def test_status_no_report():
    jobs = [
        classified(1, []),
        classified(2, ["x"], report_ok=0, epoch=1788045539 + 60),
    ]
    monitor.compute_new_failures(jobs)
    status = monitor.compute_status(jobs, None, 1788045539 + 120, {})
    assert status["status"] == monitor.STATUS_NO_REPORT


def test_status_stale_without_jobs():
    status = monitor.compute_status([], None, 1788045539, {})
    assert status["status"] == monitor.STATUS_STALE


def test_status_stale_by_age():
    jobs = [classified(1, [])]
    status = monitor.compute_status(
        jobs, None, 1788045539 + 37 * 3600, {"stale_hours": 36}
    )
    assert status["status"] == monitor.STATUS_STALE


def test_status_collector_error():
    status = monitor.compute_status([], None, 1788045539, {}, error="boom")
    assert status["status"] == monitor.STATUS_COLLECTOR_ERROR


def test_status_reports_running_job():
    running = {"id": 99}
    status = monitor.compute_status([], running, 1788045539, {})
    assert status["running"] == 1
    assert status["running_job_id"] == 99


def test_end_to_end_new_failure_then_recovery(tmp_path):
    good = load_json("job_6190943.json")
    good["group_id"] = GROUP_ID
    details = load_json("details_6190943.json")
    aggregate = load("aggregate_6190943.html")

    extra_job = good_job(6200000, "2026-08-30T10:00:00")
    extra_details = load_json("details_6190943.json")
    extra_details["job"]["testresults"].append(
        {"name": "synthetic_extra", "result": "failed"}
    )

    fetch = Fetcher()
    fetch.add(
        JOBS_PATH,
        {"jobs": [good, extra_job]},
    )
    fetch.add_job(good, details, {"TEST_GIT_HASH": "a" * 40}, aggregate)
    fetch.add_job(extra_job, extra_details, {"TEST_GIT_HASH": "b" * 40}, aggregate)

    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-30T11:00:00")
    lines = collect(cfg, fetch, now)
    status = status_line(lines)
    assert status["status"] == monitor.STATUS_NEW_FAILURES
    assert "synthetic_extra" in status["new_failure_names"]

    same_job = good_job(6200001, "2026-08-31T10:00:00")
    fetch.routes["/api/v1/jobs/6200001"] = json.dumps(same_job).encode()
    fetch.add(
        JOBS_PATH,
        {"jobs": [good, extra_job, same_job]},
    )
    fetch.add_job(same_job, extra_details, {"TEST_GIT_HASH": "b" * 40}, aggregate)
    now = monitor.parse_openqa_time("2026-08-31T11:00:00")
    lines = collect(cfg, fetch, now)
    assert status_line(lines)["status"] == monitor.STATUS_OK


def test_aborted_run_is_not_counted_in_coverage_stats(tmp_path):
    good = good_job(6190943, "2026-08-29T23:18:59")
    aborted = good_job(6338558, "2026-08-30T10:00:00")
    aborted["result"] = "failed"
    aborted_details = {
        "job": {
            "testresults": [
                {"name": "system_prepare", "result": "passed"},
                {"name": "coverage_setup", "result": "failed"},
                {"name": "curl_https", "result": "skipped"},
            ]
        }
    }

    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [good, aborted]})
    fetch.add_job(
        good,
        load_json("details_6190943.json"),
        {"TEST_GIT_HASH": "a" * 40},
        load("aggregate_6190943.html"),
    )
    fetch.add_job(aborted, aborted_details, {"TEST_GIT_HASH": "b" * 40})

    now = monitor.parse_openqa_time("2026-08-30T11:00:00")
    lines = collect(make_config(tmp_path), fetch, now)

    runs = [x for x in lines if x.startswith("binary_coverage,")]
    assert len(runs) == 1
    assert "job_id=6190943i" in runs[0]

    status = status_line(lines)
    assert status["last_job_id"] == 6338558
    assert status["last_job_result"] == "failed"
    assert status["status"] == monitor.STATUS_NO_REPORT
    assert status["new_failure_names"] == ""


def test_end_to_end_stale(tmp_path):
    fetch = Fetcher()
    fetch.add(
        JOBS_PATH,
        {"jobs": []},
    )
    lines = collect(make_config(tmp_path), fetch, 1788045539)
    assert status_line(lines)["status"] == monitor.STATUS_STALE


def test_end_to_end_collector_error(tmp_path):
    class Broken(Fetcher):
        def __call__(self, url):
            raise monitor.FetchError("down")

    lines = collect(make_config(tmp_path), Broken(), 1788045539)
    assert status_line(lines)["status"] == monitor.STATUS_COLLECTOR_ERROR


def test_one_point_per_run_and_images_for_the_latest(tmp_path):
    aggregate = load("aggregate_6190943.html")
    jobs = []
    fetch = Fetcher()
    for i in range(45):
        job = good_job(6300000 + i, "2026-08-29T23:18:59")
        jobs.append(job)
        details = load_json("details_6190943.json")
        fetch.add_job(job, details, {"TEST_GIT_HASH": "a" * 40}, aggregate)
    fetch.add(JOBS_PATH, {"jobs": jobs})
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-29T23:18:59") + 3600
    lines = collect(cfg, fetch, now)
    runs = [x for x in lines if x.startswith("binary_coverage,")]
    assert len(runs) == 45
    assert all(",images=3i," in x for x in runs)
    images = [x for x in lines if x.startswith("binary_coverage_image")]
    assert len(images) == 3
    assert all("delta_pct=0.0" in x and "prev_job_id=6300043i" in x for x in images)


def test_image_coverage_deltas(tmp_path):
    old_aggregate = (
        load("aggregate_6190943.html")
        .replace("<td>1247</td>", "<td>1300</td>", 1)
        .replace("<td>0</td>", "<td>65</td>", 1)
        .replace('bar-label">0.0%', 'bar-label">5.0%', 1)
    )
    new_aggregate = load("aggregate_6190943.html")
    old = good_job(6190943, "2026-08-29T23:18:59")
    new = good_job(6200000, "2026-08-30T10:00:00")
    details = load_json("details_6190943.json")
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [old, new]})
    fetch.add_job(old, details, {"TEST_GIT_HASH": "a" * 40}, old_aggregate)
    fetch.add_job(new, details, {"TEST_GIT_HASH": "b" * 40}, new_aggregate)
    now = monitor.parse_openqa_time("2026-08-30T11:00:00")
    lines = collect(make_config(tmp_path), fetch, now)
    lines = [
        x
        for x in lines
        if x.startswith("binary_coverage_image,") and "image=libperl.so" in x
    ]
    assert len(lines) == 1
    line = lines[0]
    assert "coverage_pct=0.0" in line
    assert "prev_pct=5.0" in line
    assert "delta_pct=-5.0" in line
    assert "delta_total=-53i" in line
    assert "prev_job_id=6190943i" in line
    assert "new_image=0i" in line


def test_cache_avoids_refetching_finished_jobs(tmp_path):
    job = good_job(6190943)
    job["group_id"] = GROUP_ID
    details = load_json("details_6190943.json")
    aggregate = load("aggregate_6190943.html")
    fetch = Fetcher()
    fetch.add(
        JOBS_PATH,
        {"jobs": [job]},
    )
    fetch.add_job(job, details, {"TEST_GIT_HASH": "a" * 40}, aggregate)
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-29T23:18:59") + 3600
    collect(cfg, fetch, now)
    detail_calls = [c for c in fetch.calls if "/details" in c]
    assert detail_calls
    fetch.calls = []
    collect(cfg, fetch, now)
    assert not [c for c in fetch.calls if "/details" in c]
    assert not [c for c in fetch.calls if "coverage_report-aggregate" in c]


def test_cache_entry_without_started_flag_is_refetched(tmp_path):
    job = good_job(6190943)
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [job]})
    fetch.add_job(
        job,
        load_json("details_6190943.json"),
        {"TEST_GIT_HASH": "a" * 40},
        load("aggregate_6190943.html"),
    )
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-29T23:18:59") + 3600
    monitor.store_cached(
        monitor.cache_path(str(tmp_path), "o3", 6190943),
        {"job": {"id": 6190943}, "classified": {"report_ok": 1}},
    )
    collect(cfg, fetch, now)
    assert [c for c in fetch.calls if "/details" in c]


def test_challenged_aggregate_is_retried_not_cached(tmp_path, capsys):
    job = good_job(6190943)
    details = load_json("details_6190943.json")
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [job]})
    challenge = "<html><title>Making sure you're not a bot!</title></html>"
    fetch.add_job(job, details, {"TEST_GIT_HASH": "a" * 40}, challenge)
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-29T23:18:59") + 3600
    lines = collect(cfg, fetch, now)
    assert status_line(lines)["status_text"] == "NO_REPORT"
    assert "aggregate could not be fetched" in capsys.readouterr().err
    fetch.add_job(
        job, details, {"TEST_GIT_HASH": "a" * 40}, load("aggregate_6190943.html")
    )
    lines = collect(cfg, fetch, now)
    assert status_line(lines)["last_ok_job_id"] == 6190943


def test_http_get_sends_allowed_headers(monkeypatch):
    seen = {}

    class Resp:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def read(self):
            return b"ok"

    def fake_urlopen(req, timeout):
        seen.update(dict(req.header_items()))
        return Resp()

    monkeypatch.setattr(monitor.urllib.request, "urlopen", fake_urlopen)
    assert monitor.http_get("https://o3.test/x") == b"ok"
    sent = dict((key.lower(), value) for key, value in seen.items())
    assert sent.get("accept") == "*/*"
    assert sent.get("user-agent") == "openqa-monitoring"


def test_new_failures_ignore_a_run_without_report():
    good = {"failed_set": ["a"], "report_ok": 1}
    timed_out = {"failed_set": ["x"], "report_ok": 0}
    next_good = {"failed_set": ["a"], "report_ok": 1}
    monitor.compute_new_failures([good, timed_out, next_good])
    assert timed_out["new_failures"] == ["x"]
    assert next_good["new_failures"] == []


def two_jobs_one_broken(tmp_path):
    good = good_job(6190943, "2026-08-29T23:18:59")
    broken = good_job(6200000, "2026-08-30T10:00:00")
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [good, broken]})
    fetch.add_job(
        good,
        load_json("details_6190943.json"),
        {"TEST_GIT_HASH": "a" * 40},
        load("aggregate_6190943.html"),
    )
    fetch.add("/api/v1/jobs/6200000/details", "<html>proxy error</html>")
    return make_config(tmp_path), fetch


def test_broken_job_is_skipped_not_fatal(tmp_path, capsys):
    cfg, fetch = two_jobs_one_broken(tmp_path)
    now = monitor.parse_openqa_time("2026-08-30T11:00:00")
    lines = collect(cfg, fetch, now)
    assert len([x for x in lines if x.startswith("binary_coverage,")]) == 1
    status = status_line(lines)
    assert status["skipped_jobs"] == 1
    assert status["last_ok_job_id"] == 6190943
    assert status["status"] == monitor.STATUS_COLLECTOR_ERROR
    assert "skipping job 6200000" in capsys.readouterr().err
    assert not (tmp_path / "o3-6200000.json").exists()


def test_unexpected_error_becomes_collector_error(tmp_path, capsys):
    fetch = Fetcher()
    fetch.add(JOBS_PATH, "<html>maintenance</html>")
    lines = collect(make_config(tmp_path), fetch, 1788045539)
    assert status_line(lines)["status"] == monitor.STATUS_COLLECTOR_ERROR
    assert "collector error" in capsys.readouterr().err


def test_malformed_aggregate_counts_as_missing():
    page = load("aggregate_6190943.html").replace("<td>1247</td>", "<td>n/a</td>", 1)
    assert "<td>n/a</td>" in page

    def fetch(url):
        return page.encode()

    assert monitor.fetch_aggregate({"url": BASE}, 1, fetch) is None


def test_cache_keeps_only_the_image_count(tmp_path):
    job = good_job(6190943)
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [job]})
    fetch.add_job(
        job,
        load_json("details_6190943.json"),
        {"TEST_GIT_HASH": "a" * 40},
        load("aggregate_6190943.html"),
    )
    now = monitor.parse_openqa_time("2026-08-29T23:18:59") + 3600
    collect(make_config(tmp_path), fetch, now)
    entry = json.loads((tmp_path / "o3-6190943.json").read_text())
    assert entry["classified"]["aggregate"]["images"] == 3


def test_prune_cache_removes_entries_past_the_window(tmp_path):
    old = tmp_path / "o3-1.json"
    new = tmp_path / "o3-2.json"
    other = tmp_path / "osd-3.json"
    for path in (old, new, other):
        path.write_text("{}")
    os.utime(str(old), (1000, 1000))
    os.utime(str(other), (1000, 1000))
    monitor.prune_cache(str(tmp_path), "o3", 2000)
    assert not old.exists()
    assert new.exists()
    assert other.exists()


def add_image_row(aggregate, name):
    row = (
        "<tr>\n<td>%s</td>\n<td>300</td>\n<td>30</td>\n"
        '<td>\n<div class="bar">\n<span class="bar-label">10.0%%</span>\n'
        "</div>\n</td>\n</tr>\n" % name
    )
    return aggregate.replace("</tbody>", row + "</tbody>", 1)


def image_lines(lines):
    return [x for x in lines if x.startswith("binary_coverage_image,")]


def test_new_image_marker_clears_on_the_next_run(tmp_path):
    base = load("aggregate_6190943.html")
    with_new = add_image_row(base, "libnew.so")
    details = load_json("details_6190943.json")
    a = good_job(6190943, "2026-08-29T23:18:59")
    b = good_job(6200000, "2026-08-30T10:00:00")
    c = good_job(6200001, "2026-08-31T10:00:00")
    fetch = Fetcher()
    fetch.add_job(a, details, {"TEST_GIT_HASH": "a" * 40}, base)
    fetch.add_job(b, details, {"TEST_GIT_HASH": "b" * 40}, with_new)
    fetch.add_job(c, details, {"TEST_GIT_HASH": "c" * 40}, with_new)
    cfg = make_config(tmp_path)

    fetch.add(JOBS_PATH, {"jobs": [a]})
    run1 = image_lines(
        collect(cfg, fetch, monitor.parse_openqa_time("2026-08-30T00:00:00"))
    )
    assert all("new_image=0i" in x for x in run1)
    assert all("prev_job_id=0i" in x for x in run1)

    fetch.add(JOBS_PATH, {"jobs": [a, b]})
    run2 = image_lines(
        collect(cfg, fetch, monitor.parse_openqa_time("2026-08-30T11:00:00"))
    )
    new_rows = [x for x in run2 if "image=libnew.so" in x]
    assert len(new_rows) == 1
    assert "new_image=1i" in new_rows[0]
    assert all("new_image=0i" in x for x in run2 if "image=libnew.so" not in x)

    fetch.add(JOBS_PATH, {"jobs": [a, b, c]})
    run3 = image_lines(
        collect(cfg, fetch, monitor.parse_openqa_time("2026-08-31T11:00:00"))
    )
    old_new = [x for x in run3 if "image=libnew.so" in x]
    assert len(old_new) == 1
    assert "new_image=0i" in old_new[0]
    assert "prev_job_id=6200000i" in old_new[0]
    assert "delta_pct=0.0" in old_new[0]


def test_image_data_is_backfilled_into_the_cache(tmp_path):
    job = good_job(6190943)
    details = load_json("details_6190943.json")
    aggregate = load("aggregate_6190943.html")
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [job]})
    fetch.add_job(job, details, {"TEST_GIT_HASH": "a" * 40}, aggregate)
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-30T00:00:00")
    collect(cfg, fetch, now)
    path = tmp_path / "o3-6190943.json"
    entry = json.loads(path.read_text())
    del entry["classified"]["image_data"]
    path.write_text(json.dumps(entry))
    lines = collect(cfg, fetch, now)
    assert image_lines(lines)
    entry = json.loads(path.read_text())
    assert entry["classified"]["image_data"]


def test_images_skipped_when_previous_run_is_unavailable(tmp_path, capsys):
    a = good_job(6190943, "2026-08-29T23:18:59")
    b = good_job(6200000, "2026-08-30T10:00:00")
    details = load_json("details_6190943.json")
    aggregate = load("aggregate_6190943.html")
    fetch = Fetcher()
    fetch.add(JOBS_PATH, {"jobs": [a, b]})
    fetch.add_job(a, details, {"TEST_GIT_HASH": "a" * 40}, aggregate)
    fetch.add_job(b, details, {"TEST_GIT_HASH": "b" * 40}, aggregate)
    cfg = make_config(tmp_path)
    now = monitor.parse_openqa_time("2026-08-30T11:00:00")
    collect(cfg, fetch, now)
    path = tmp_path / "o3-6190943.json"
    entry = json.loads(path.read_text())
    del entry["classified"]["image_data"]
    path.write_text(json.dumps(entry))
    del fetch.routes["/tests/6190943/file/coverage_report-aggregate.html"]
    lines = collect(cfg, fetch, now)
    assert not image_lines(lines)
    assert "no image data for job 6190943" in capsys.readouterr().err
