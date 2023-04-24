{%- if not grains.get('noservices', False) %}
auto_upgrade_service:
  file.managed:
    - name: /etc/systemd/system/auto-upgrade.service
    - source: salt://auto-upgrade/auto-upgrade.service
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_upgrade_service

auto_upgrade_timer:
  file.managed:
    - name: /etc/systemd/system/auto-upgrade.timer
    - source: salt://auto-upgrade/auto-upgrade.timer
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_upgrade_timer

auto-upgrade.timer:
  service.running:
    - enable: True
    - require:
      - auto_upgrade_timer
{%- endif %}
