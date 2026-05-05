rebootmgr:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# it should be possible to at least change the file for rebootmgr.conf in
# environments with no service management but this failed so far in tests so
# excluding as well
{%- if not grains.get('noservices', False) %}
{% set rebootmgr_version = salt['pkg.version']('rebootmgr') %}
{% set rebootmgr_config = "/etc/rebootmgr.conf" if salt['pkg.version_cmp'](rebootmgr_version, '3.0') == -1 else "/etc/rebootmgr/rebootmgr.conf.d/20-old-rebootmgr.conf" %}
{{ rebootmgr_config }}:
  file.replace:
    - pattern: '^(window-start=)(.*)$'
    - repl: 'window-start=Sun, 03:30'
    - require:
      - rebootmgr
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: {{ rebootmgr_config }}

rebootmgr.service:
  service.running:
    - enable: True
{%- endif %}

