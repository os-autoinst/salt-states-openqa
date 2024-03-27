bluez:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

bluetooth.service:
  service.running:
    - enable: True

/etc/systemd/system/bluetooth-config.service:
  file.managed:
    - create: True
    - contents: |
        [Unit]
        Description=Configure bluetooth
        After=bluetooth.target

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/bluetoothctl power on
        ExecStart=/usr/bin/bluetoothctl system-alias openQA-worker
        ExecStart=/usr/bin/bluetoothctl discoverable-timeout 0
        ExecStart=/usr/bin/bluetoothctl discoverable on
        ExecStart=/usr/bin/bluetoothctl show
        RemainAfterExit=yes

        [Install]
        WantedBy=multi-user.target

bluetooth-config.service:
  service.running:
    - enable: True
