rebootmgr:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

{% set rebootmgr_version = salt['pkg.version']('rebootmgr') %}
{% set is_legacy = salt['pkg.version_cmp'](rebootmgr_version, '3.0') == -1 %}
{% set legacy_config = "/etc/rebootmgr.conf" %}
{% set rebootmgr_config = "/etc/rebootmgr/rebootmgr.conf.d/20-old-rebootmgr.conf" %}
{% set reboot_time = "Sun, 03:30:00" %}

# only handle the config if the version comparison was successful
{%- if is_legacy %}
ensure_legacy_file:
  file.managed:
    - name: {{ legacy_config }}
    - makedirs: True

ensure_legacy_config:
  file.replace:
    - name: {{ legacy_config }}
    - pattern: '^(window-start=)(.*)$'
    - repl: 'window-start={{ reboot_time }}'
    - append_if_not_found: True
{%- if grains.get('noservices', False) %}
    - ignore_if_missing: True # the previous file creation gets mocked in tests
{%- endif %}
{%- elif is_legacy %}
ensure_absent:
  file.absent:
    - name: {{ legacy_config }}

ensure_file:
  file.managed:
    - name: {{ rebootmgr_config }}
    - makedirs: True

ensure_config:
  ini.options_present:
    - name: {{ rebootmgr_config }}
    - sections:
        rebootmgr:
          window-start: {{ reboot_time }}
{% endif %}

{%- if not grains.get('noservices', False) %}
# rebootmgr does not support reloading so we just restart it on file changes
rebootmgr.service:
  service.running:
    - enable: True
    - watch:
      - file: {{ rebootmgr_config }}
      - file: {{ legacy_config }}
{%- endif %}

