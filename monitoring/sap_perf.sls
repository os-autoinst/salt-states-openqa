sap_perf.packages:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - python3-requests
## newer python versions include dataclasses directly
{% if 'Tumbleweed' not in grains['oscodename'] %}
      - python3-dataclasses
{% endif %}

/etc/telegraf/telegraf.d/sap_perf.conf:
  file.managed:
    - source: salt://monitoring/sap_perf/sap_perf.conf
    - makedirs: True


/etc/telegraf/scripts/hanaperf_gitlab.py:
  file.managed:
    - source: salt://monitoring/sap_perf/scripts/hanaperf_gitlab.py
    - mode: "0755"
