maintenance_queue.packages:
  pkg.installed:
    - resolve_capabilities: true
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - python3-pandas


/etc/telegraf/telegraf.d/maintenance_queue.conf:
  file.managed:
    - source: salt://monitoring/maintenance_queue/maintenance_queue.conf
    - makedirs: true


/etc/telegraf/scripts/maintenance_queue_monitor.py:
  file.managed:
    - source: salt://monitoring/maintenance_queue/scripts/maintenance_queue_monitor.py
    - mode: "0775"
