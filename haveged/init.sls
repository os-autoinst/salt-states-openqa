/etc/systemd/system/haveged.service.d/override.conf:
  file.managed:
    - source:
      - salt://haveged/override.conf
