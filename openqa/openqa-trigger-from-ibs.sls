geekotest:
  user:
    - present

{% set dir = '/opt/openqa-trigger-from-ibs/' %}
{% set plugindir = '/opt/openqa-trigger-from-ibs-plugin/' %}
{{ dir }}:
  file.directory:
    - name: {{ dir }}
    - user: geekotest

{{ plugindir }}:
  file.directory:
    - name: {{ plugindir }}
    - user: geekotest

openqa-trigger-from-ibs:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    # python3 is now a capability provided by a minor version package
    - resolve_capabilities: True
    - pkgs:
      - git
      - python3
      - ca-certificates-suse

  git.latest:
    - name: https://github.com/os-autoinst/openqa-trigger-from-obs
    - target: {{ dir }}
    - user: geekotest

openqa-trigger-from-ibs-plugin:
  git.latest:
    - name: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs-plugin
    - target: {{ plugindir }}
    - user: geekotest

{% macro scriptgen(prj) -%}
{{ prj }}:
  cmd.run:
    - name: su geekotest -c 'mkdir -p {{ prj }} && python3 script/scriptgen.py {{ prj }}'
    - cwd: {{ dir }}
{%- endmacro %}

{{ scriptgen('SUSE:SLE-15-SP4:GA:TEST') }}

{% for i in ['A','B','C','D','E','F','G','H','S','Y','V'] %}
{{ scriptgen('SUSE:SLE-15-SP4:GA:Staging:' + i) }}
{% endfor %}

{{ scriptgen('SUSE:SLE-12-SP5:Update:Products:SLERT') }}
{{ scriptgen('SUSE:SLE-15-SP2:Update:WSL') }}
{{ scriptgen('SUSE:SLE-15-SP3:Update:WSL') }}
{{ scriptgen('SUSE:SLE-15-SP2:Update:Products:MicroOS:TEST') }}
{{ scriptgen('SUSE:SLE-15-SP3:Update:Products:MicroOS51') }}
{{ scriptgen('SUSE:SLE-15-SP1:Update:QR') }}
{{ scriptgen('SUSE:SLE-15-SP2:Update:QR') }}
{{ scriptgen('SUSE:SLE-15-SP3:Update:QR') }}
# Container image updates
{{ scriptgen('SUSE:SLE-12-SP3:Docker:Update:CR') }}
{{ scriptgen('SUSE:SLE-12-SP4:Docker:Update:CR') }}
{{ scriptgen('SUSE:SLE-12-SP5:Docker:Update:CR') }}
{{ scriptgen('SUSE:SLE-15:Update:CR') }}
{{ scriptgen('SUSE:SLE-15-SP1:Update:CR') }}
{{ scriptgen('SUSE:SLE-15-SP2:Update:CR') }}
{{ scriptgen('SUSE:SLE-15-SP3:Update:CR') }}

{% for i in ['A','B'] %}
{{ scriptgen('SUSE:SLE-15-SP3:Update:Products:MicroOS51:Staging:' + i) }}
{% endfor %}
