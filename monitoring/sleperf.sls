sleperf.packages:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - python3-requests


/etc/telegraf/telegraf.d/sleperf.conf:
  file.managed:
    - source: salt://monitoring/sleperf/sleperf.conf
    - makedirs: True

/etc/telegraf/scripts/collect_sleperf_test.py:
  file.managed:
    - source: salt://monitoring/sleperf/scripts/collect_sleperf_test.py
    - mode: "0755"
