logrotate:
  pkg.installed:
    - refresh: False

/etc/systemd/system/logrotate.timer.d/override.conf:
  file.managed:
    - source:
      - salt://logrotate/logrotate.timer_override.conf
    - makedirs: true

{%- if not grains.get('noservices', False) %}
daemon-reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/logrotate.timer.d/override.conf
{%- endif %}
