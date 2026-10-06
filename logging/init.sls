/etc/systemd/system/systemd-journal-flush.service.d/startup-timeout.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Service]
        TimeoutStartSec=300

# Avoid varlink IPC in root systemd services to prevent boot ordering deadlocks
# and missing Rotate method in wtmpdb 0.74 (https://progress.opensuse.org/issues/207669, https://bugzilla.suse.com/show_bug.cgi?id=1284234)
/etc/systemd/system/wtmpdb-update-boot.service.d/direct-db.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Service]
        ExecStart=
        ExecStart=/usr/bin/wtmpdb boot -f /var/lib/wtmpdb/wtmp.db
        ExecStop=
        ExecStop=/usr/bin/wtmpdb shutdown -f /var/lib/wtmpdb/wtmp.db

/etc/systemd/system/wtmpdb-rotate.service.d/direct-db.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Service]
        ExecStart=
        ExecStart=/usr/bin/wtmpdb rotate -f /var/lib/wtmpdb/wtmp.db
