/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://etc/logrotate.d/postgresql
/etc/logrotate.d/openqa:
  file.managed:
    - source: salt://etc/logrotate.d/openqa
