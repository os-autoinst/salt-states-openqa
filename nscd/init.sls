/usr/bin/mkdir_nscd:
  file.managed:
    - source:
      - salt://nscd/mkdir_nscd
    - mode: 644

/etc/systemd/system/nscd.service.d/override.conf:
  file.managed:
    - source:
      - salt://nscd/override.conf
    - makedirs: True
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/nscd.service.d/override.conf
