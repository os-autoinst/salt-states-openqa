cronie:
  pkg.installed

/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://etc/master/logrotate.d/postgresql
/etc/logrotate.d/openqa:
  file.managed:
    - source: salt://etc/master/logrotate.d/openqa
/etc/cron.d/SLES.CRON:
  file.managed:
    - source: salt://etc/master/cron.d/SLES.CRON
