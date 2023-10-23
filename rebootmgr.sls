rebootmgr:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

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

