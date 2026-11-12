"""Structural checks for the binary coverage Grafana dashboard."""

import json
import os

HERE = os.path.dirname(__file__)
DASHBOARD = os.path.join(HERE, "..", "monitoring", "grafana", "binary_coverage.json")


def load():
    with open(DASHBOARD) as f:
        return json.load(f)


def panel(dashboard, title):
    for item in dashboard["panels"]:
        if item.get("title") == title:
            return item
    raise AssertionError("panel %r not found" % title)


def queries(item):
    return [target["query"] for target in item.get("targets", [])]


def override(item, name):
    for entry in item["fieldConfig"]["overrides"]:
        if entry["matcher"]["options"] == name:
            return entry
    raise AssertionError("override %r not found" % name)


def properties(entry):
    return {item["id"]: item["value"] for item in entry["properties"]}


def test_panels_use_the_influxdb_datasource():
    dashboard = load()
    for item in dashboard["panels"]:
        if item.get("type") == "row":
            continue
        assert item["datasource"] == {"type": "influxdb", "uid": "000000001"}
        for target in item["targets"]:
            assert target["datasource"] == {"type": "influxdb", "uid": "000000001"}


def test_coverage_stats_only_use_runs_with_a_report():
    dashboard = load()
    for title in (
        "Average coverage %",
        "Functions",
        "Instrumented images",
        "Failed modules per run",
        "Coverage runs",
    ):
        for query in queries(panel(dashboard, title)):
            assert '"report_ok" = 1' in query, (title, query)


def test_last_job_panel_shows_job_and_result():
    item = panel(load(), "Last job")
    assert item["type"] == "table"
    query = queries(item)[0]
    assert 'last("last_job_id") AS "job"' in query
    assert 'last("last_job_result") AS "result"' in query


def test_last_job_result_mappings():
    item = panel(load(), "Last job")
    props = properties(override(item, "result"))
    options = props["mappings"][0]["options"]
    assert options["passed"]["color"] == "green"
    assert options["softfailed"]["color"] == "green"
    assert options["failed"]["color"] == "red"
    assert options["parallel_failed"]["color"] == "red"
    assert options["timeout_exceeded"]["color"] == "red"
    assert options["incomplete"]["color"] == "orange"
    assert options[""]["text"] == "NO DATA"
    assert options[""]["color"] == "red"


def test_last_job_zero_is_none_without_a_dead_link():
    item = panel(load(), "Last job")
    props = properties(override(item, "job"))
    assert props["mappings"][0]["options"]["0"]["text"] == "none"
    assert "links" not in props
