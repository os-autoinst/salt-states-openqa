rsnapshot.pkgs:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - rsnapshot

/etc/rsnapshot.conf:
  file.managed:
    - source: salt://etc/backup/rsnapshot.conf
    - user: root
    - group: root
    - mode: 644

/etc/cron.d/rsnapshot.cron:
  file.managed:
    - source: salt://etc/backup/rsnapshot.cron
