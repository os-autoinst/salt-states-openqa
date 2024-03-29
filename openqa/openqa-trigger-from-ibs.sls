geekotest:
  user:
    - present

{% set dir = '/opt/openqa-trigger-from-ibs/' %}
{% set plugindir = '/opt/openqa-trigger-from-ibs-plugin/' %}
{{ dir }}:
  file.directory:
    - user: geekotest

{{ plugindir }}:
  file.directory:
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

  git.latest:
    - name: https://github.com/os-autoinst/openqa-trigger-from-obs
    - target: {{ dir }}
    - user: geekotest

https://gitlab.suse.de/openqa/openqa-trigger-from-ibs-plugin:
  git.latest:
    - target: {{ plugindir }}
    - user: geekotest

{% macro scriptgen(prj) -%}
{{ prj }}:
  cmd.run:
    - name: su geekotest -c 'mkdir -p {{ prj }} && python3 script/scriptgen.py {{ prj }}'
    - cwd: {{ dir }}
{%- endmacro %}

{{ scriptgen('SUSE:SLE-15-SP6:GA:TEST') }}

{% for i in ['A','B','C','D','E','F','G','H','S','Y','V'] %}
{{ scriptgen('SUSE:SLE-15-SP6:GA:Staging:' + i) }}
{% endfor %}

{% for i in ['A','B','C','D','E','F','G','H','S','V','Y'] %}
{{ scriptgen('SUSE:ALP:Source:Standard:1.0:Staging:' + i) }}
{% endfor %}

{{ scriptgen('SUSE:SLE-12-SP5:Update:Products:SLERT') }}
{{ scriptgen('SUSE:SLE-15-SP4:Update:WSL') }}
{{ scriptgen('SUSE:SLE-15-SP5:Update:WSL') }}
{{ scriptgen('SUSE:SLE-15-SP6:Update:WSL') }}
{{ scriptgen('SUSE:ALP:Products:SLMicro:6.0:ToTest') }}
{{ scriptgen('SUSE:SLE-15-SP4:Update:QR:TEST') }}
{{ scriptgen('SUSE:SLE-15-SP5:Update:QR:TEST') }}
{{ scriptgen('SUSE:SLE-15-SP5:Update:BCI') }}
{{ scriptgen('SUSE:SLE-15-SP6:Update:BCI') }}
{{ scriptgen('SUSE:SLE-15-SP4:Update:Products:SLERT') }}
{{ scriptgen('Devel:Elemental:Teal53') }}
