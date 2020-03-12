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
    - pkgs:
      - git
      - python3

  git.latest:
    - name: https://github.com/andrii-suse/openqa-trigger-from-obs
    - target: {{ dir }}
    - user: geekotest

openqa-trigger-from-ibs-plugin:
  pkg.installed:
    - refresh: False
    - pkgs:
      - git
      - python3

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

{{ scriptgen('SUSE:SLE-15-SP2:GA:TEST') }}

{% for i in ['A','B','C','D','E','F','G','H','S','Y','V'] %}
{{ scriptgen('SUSE:SLE-15-SP2:GA:Staging:' + i) }}
{% endfor %}

{{ scriptgen('SUSE:SLE-12-SP5:Update:Products:SLERT') }}
{{ scriptgen('SUSE:SLE-15-SP2:Update:WSL') }}
