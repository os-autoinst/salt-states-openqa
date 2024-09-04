sleperf.packages:
  pkg.installed:
    - resolve_capabilities: true
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - python3-requests


# Currently not used due to https://progress.opensuse.org/issues/166235
/etc/telegraf/telegraf.d/sleperf.conf:
  file.absent

/etc/telegraf/scripts/collect_sleperf_test.py:
  file.managed:
    - source: salt://monitoring/sleperf/scripts/collect_sleperf.py
    - mode: "0755"
