/etc/systemd/system/haveged.service.d/override.conf:
  file.managed:
    - source:
      - salt://haveged/override.conf
    - makedirs: True
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/haveged.service.d/override.conf
