sap_perf.packages:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - python3-requests


/etc/telegraf/telegraf.d/sap_perf.conf:
  file.managed:
    - source: salt://monitoring/sap_perf/sap_perf.conf
    - makedirs: True


/etc/telegraf/scripts/gitlab_commits.py:
  file.managed:
    - source: salt://monitoring/sap_perf/scripts/gitlab_commits.py
    - mode: "0755"
