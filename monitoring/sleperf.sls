sleperf.packages:
  pkg.installed:
    - resolve_capabilities: true
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - python3-requests


/etc/telegraf/telegraf.d/sleperf.conf:
  file.managed:
    - source: salt://monitoring/sleperf/sleperf.conf
    - makedirs: true

/etc/telegraf/scripts/collect_sleperf_test.py:
  file.managed:
    - source: salt://monitoring/sleperf/scripts/collect_sleperf.py
    - mode: "0755"
