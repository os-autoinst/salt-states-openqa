{%- if not grains.get('noservices', False) %}
auto_update_service:
  file.managed:
    - name: /etc/systemd/system/auto-update.service
    - source: salt://auto-update/auto-update.service
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_update_service

auto_update_timer:
  file.managed:
    - name: /etc/systemd/system/auto-update.timer
    - source: salt://auto-update/auto-update.timer
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

rebootmgr:
  pkg.installed:
    - refresh: False

# it should be possible to at least change the file for rebootmgr.conf in
# environments with no service management but this failed so far in tests so
# excluding as well
{%- if not grains.get('noservices', False) %}
/etc/rebootmgr.conf:
  file.replace:
    - pattern: '^(window-start=)(.*)$'
    - repl: 'window-start=Sun, 03:30'
    - require:
      - rebootmgr
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/rebootmgr.conf

rebootmgr.service:
  service.running:
    - enable: True
{%- endif %}
