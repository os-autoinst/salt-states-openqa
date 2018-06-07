/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://logrotate/postgresql
/etc/logrotate.d/openqa:
  file.managed:
    - source: salt://logrotate/openqa
