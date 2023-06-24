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
    - mode: "0644"

{%- if not grains.get('noservices', False) %}
# add the service and timers for rsnapshot
rsnapshot_service:
  file.managed:
    - name: /etc/systemd/system/rsnapshot@.service
    - source: salt://etc/backup/systemd/system/rsnapshot@.service
{% for backup_type in ['alpha', 'beta'] %}
rsnapshot_timer_{{ backup_type }}:
  file.managed:
    - name: /etc/systemd/system/rsnapshot-{{ backup_type }}.timer
    - source: salt://etc/backup/systemd/system/rsnapshot-{{ backup_type }}.timer
rsnapshot-{{ backup_type }}.timer:
  service.running:
    - enable: True
    - require:
      - rsnapshot_service
      - rsnapshot_timer_{{ backup_type }}
{% endfor %}

# ssh key files and config for backup
# https://progress.opensuse.org/issues/96269
# Generated with
# `ssh-keygen -t ed25519 -N '' -C 'root@storage.oqa.suse.de, backup OSD' -f id_ed25519.backup_osd`
/root/.ssh/id_ed25519.backup_osd:
  file.managed:
    - mode: "0600"
    - user: root
    - group: root
    - contents_pillar: id_ed25519.backup_osd

/root/.ssh/config:
  file.managed:
    - contents: |
        Host openqa.suse.de osd
          HostName openqa.suse.de
          IdentityFile /root/.ssh/id_ed25519.backup_osd
        Host openqa.opensuse.org o3 ariel
            HostName proxy-opensuse.suse.de
            Port 2215

{%- endif %}
