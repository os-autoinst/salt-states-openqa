/etc/telegraf.d/maintenance_queue.conf:
  file.managed:
    - source: salt://monitoring/maintenance_queue/maintenance_queue.conf


/etc/telegraf/scripts/maintenance_queue_monitor.py:
  file.managed:
    - source: salt://monitoring/maintenance_queue/scripts/maintenance_queue_monitor.py
