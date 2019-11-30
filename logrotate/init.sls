logrotate:
  pkg.installed:
    - refresh: False

/etc/systemd/system/logrotate.timer.d/override.conf:
   file.absent

/etc/systemd/system/logrotate-openqa.service:
  file.managed:
    - source:
      - salt://logrotate/logrotate-openqa.service
    - makedirs: true

/etc/systemd/system/logrotate-openqa.timer:
  file.managed:
    - source:
      - salt://logrotate/logrotate-openqa.timer
    - makedirs: true

{%- if not grains.get('noservices', False) %}
logrotate-openqa.timer:
  service.running:
    - enable: True
    - require:
      - auto_update_timer

daemon-reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/logrotate-openqa.service
      - file: /etc/systemd/system/logrotate-openqa.timer
{%- endif %}
