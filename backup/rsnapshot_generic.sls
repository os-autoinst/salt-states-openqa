rsnapshot.pkgs:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - filesystem
      - rsnapshot
      - nfs-client

nfs_backup_prg2_mounted:
  mount.fstab_present:
    # NFS share on prg2 netapp
    - name: "10.144.128.241:/openqa-backup-storage"
    - fs_file: /storage
    - fs_vfstype: nfs
    - fs_mntops: "rw,nofail,retry=30,x-systemd.mount-timeout=30m,x-systemd.automount,nolock"
    - not_change: False

/etc/rsnapshot.conf:
  file.managed:
    - source: salt://etc/backup/rsnapshot_generic.conf
    - user: root
    - group: root
    - mode: "0644"

/usr/local/bin/backup_check.sh:
  file.managed:
    - source: salt://usr/local/bin/backup_check.sh
    - user: root
    - group: root
    - mode: "0755"

/etc/systemd/system/backup_check.service:
  file.managed:
    - contents: |
         [Unit]
         Description=Check if backup worked
         [Service]
         Type=oneshot
         ExecStart=/usr/local/bin/backup_check.sh

/etc/systemd/system/backup_check.timer:
  file.managed:
    - contents: |
        [Unit]
        Description=Check backup
        [Timer]
        OnCalendar=23:59
        Persistent=True
        Unit=backup_check.service
        [Install]
        WantedBy=timers.target

{% if not grains.get('noservices', False) %}
  service.running:
    - name: backup_check.timer
    - enable: true
{% endif %}

/etc/cron.d/rsnapshot.cron:
  file.absent

/etc/systemd/system/rsnapshot@.service:
  file.managed:
    - source: salt://etc/backup/systemd/system/rsnapshot@.service

{% set backups = {'alpha':'0/4:38', 'beta':'04:12', 'gamma':'Sat 04:24', 'delta':'*-*-01 02:17'} %}
{% for backup_type in backups %}
/etc/systemd/system/rsnapshot-{{ backup_type }}.timer:
  file.managed:
    - contents: |
        [Unit]
        Description=Regular backup
        [Timer]
        OnCalendar={{ backups[backup_type] }}
        Persistent=True
        Unit=rsnapshot@{{ backup_type }}.service
        [Install]
        WantedBy=timers.target

{% if not grains.get('noservices', False) %}
  service.running:
    - name: rsnapshot-{{ backup_type }}.timer
    - enable: true
{% endif %}
{% endfor %}

# still relies on an ssh key for the root user that is authorized on o3
/root/.ssh/config:
  file.managed:
    - contents: |
        # This file is generated by salt - don't touch
        Host openqa.opensuse.org o3 ariel
            HostName ariel.dmz-prg2.suse.org
            # Restrict to IPv4 due to IPv6 routing problems
            # see https://progress.opensuse.org/issues/133358
            AddressFamily inet
    - user: root
    - group: root
    - mode: "0600"
