python3-usbsdmux:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/udev/rules.d/99-piworker-permission.rules:
  file.managed:
    - create: True
    - contents: |
        ACTION=="add", SUBSYSTEM=="scsi_generic", KERNEL=="sg[0-9]", ATTRS{manufacturer}=="Linux Automation GmbH", ATTRS{product}=="usb-sd-mux*", OWNER="_openqa-worker"
        ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd*", ATTRS{manufacturer}=="Linux Automation GmbH", ATTRS{product}=="usb-sd-mux*", OWNER="_openqa-worker"

_openqa-worker:
  user.present:
    - remove_groups: False
    - groups:
      - dialout
      - video

apparmor:
  service.masked
