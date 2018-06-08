/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://etc/logrotate.d/postgresql
/etc/logrotate.d/openqa:
  file.managed:
    - source: salt://etc/logrotate.d/openqa
/etc/cron.d/SLES.CRON:
  file.managed:
    - source: salt://etc/cron.d/SLES.CRON
