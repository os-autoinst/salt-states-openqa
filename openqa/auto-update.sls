{%- if not grains.get('noservices', False) %}
auto_update_service:
  file.managed:
    - name: /etc/systemd/system/auto-update.service
    - source: salt://openqa/auto-update.service
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_update_service

auto_update_timer:
  file.managed:
    - name: /etc/systemd/system/auto-update.timer
    - source: salt://openqa/auto-update.timer
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_update_timer

auto-update.timer:
  service.running:
    - enable: True
    - require:
      - auto_update_timer
{%- endif %}
