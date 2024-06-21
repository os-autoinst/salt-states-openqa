cronie:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/systemd/system/nfs-server.service.d/require-mount.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        # Prevent NFS server to serve the unmounted empty directory in case of
        # temporary disablement of mount entries in /etc/fstab
        [Unit]
        ConditionPathIsMountPoint=/var/lib/openqa/share

{%- if not grains.get('noservices', False) %}
nfs-server:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/systemd/system/nfs-server.service.d/require-mount.conf
      - file: /etc/exports
{%- endif %}

/etc/logrotate.d/postgresql:
  file.managed:
    - source: salt://etc/master/logrotate.d/postgresql
/etc/logrotate.d/openqa:
  file.managed:
    - source: salt://etc/master/logrotate.d/openqa
/etc/cron.d/SLES.CRON:
  file.managed:
    - source: salt://etc/master/cron.d/SLES.CRON
/etc/cron.hourly/logrotate:
  file.absent
/etc/exports:
  file.managed:
    - source: salt://etc/master/exports
/etc/tmpfiles.d/fs-tmp.conf:
  file.managed:
    - source: salt://etc/master/tmpfiles.d/fs-tmp.conf
/etc/tmpfiles.d/fs-var-tmp.conf:
  file.managed:
    - source: salt://etc/master/tmpfiles.d/fs-var-tmp.conf
