rsnapshot.pkgs:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - filesystem
      - rsnapshot

/etc/rsnapshot.conf:
  file.managed:
    - source: salt://etc/backup/rsnapshot.conf
    - user: root
    - group: root
    - mode: 644

{%- if not grains.get('noservices', False) %}
/etc/cron.d/rsnapshot.cron:
  file.managed:
    - source: salt://etc/backup/rsnapshot.cron

# ssh key files and config for backup
# https://progress.opensuse.org/issues/96269
# Generated with
# `ssh-keygen -t ed25519 -N '' -C 'root@storage.qa.suse.de, backup OSD' -f id_ed25519.backup_osd`
/root/.ssh/id_ed25519.backup_osd:
  file.managed:
    - mode: 600
    - user: root
    - group: root
    - contents_pillar: id_ed25519.backup_osd

/root/.ssh/config:
  file.managed:
    - contents: |
        Host openqa.suse.de osd
          HostName openqa.suse.de
          IdentityFile /root/.ssh/id_ed25519.backup_osd

{%- endif %}
