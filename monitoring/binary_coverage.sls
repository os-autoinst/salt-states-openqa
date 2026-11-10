include:
  - monitoring.telegraf

/etc/binary_coverage/collector.json:
  file.managed:
    - source: salt://monitoring/binary_coverage/collector.json
    - template: jinja
    - makedirs: true


/var/cache/binary_coverage:
  file.directory:
    - makedirs: true


/etc/telegraf/scripts/binary_coverage_monitor.py:
  file.managed:
    - source: salt://monitoring/binary_coverage/scripts/binary_coverage_monitor.py
    - mode: "0775"
    - makedirs: true


/etc/telegraf/telegraf.d/binary_coverage.conf:
  file.managed:
    - source: salt://monitoring/binary_coverage/binary_coverage.conf
    - makedirs: true
    - require:
        - file: /etc/binary_coverage/collector.json
        - file: /etc/telegraf/scripts/binary_coverage_monitor.py
{%- if not grains.get('noservices', False) %}
    # telegraf.sls only watches telegraf.d/* on webui and worker hosts
    - watch_in:
        - service: telegraf
{%- endif %}
