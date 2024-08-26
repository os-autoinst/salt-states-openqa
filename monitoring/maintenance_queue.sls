maintenance_queue.packages:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
        - python3-pandas


/etc/telegraf/telegraf.d/maintenance_queue.conf:
  file.managed:
    - source: salt://monitoring/maintenance_queue/maintenance_queue.conf
    - makedirs: True


/etc/telegraf/scripts/maintenance_queue_monitor.py:
  file.managed:
    - source: salt://monitoring/maintenance_queue/scripts/maintenance_queue_monitor.py
