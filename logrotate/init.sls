/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://logrotate/postgresql
