/etc/systemd/system/ca-certificates.service.d/override.conf:
  file.managed:
    - source: salt://ca-certificates/override.conf
    - makedirs: True
