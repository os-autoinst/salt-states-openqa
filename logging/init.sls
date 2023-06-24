/etc/systemd/system/systemd-journal-flush.service.d/startup-timeout.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Service]
        TimeoutStartSec=300
