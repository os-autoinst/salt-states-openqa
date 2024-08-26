submissions_queue.packages:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
        - python3-pandas


/etc/telegraf/telegraf.d/submissions_queue.conf:
  file.managed:
    - source: salt://monitoring/submissions_queue/submissions_queue.conf
    - makedirs: True


/etc/telegraf/scripts/submissions_queue_monitor.py:
  file.managed:
    - source: salt://monitoring/submissions_queue/scripts/submissions_queue_monitor.py
