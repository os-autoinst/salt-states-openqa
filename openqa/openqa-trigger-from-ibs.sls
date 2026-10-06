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
    - name: git@github.com:os-autoinst/openqa-trigger-from-obs.git
    - target: {{ dir }}
    - user: geekotest

https://gitlab.suse.de/openqa/openqa-trigger-from-ibs-plugin:
  git.latest:
    - target: {{ plugindir }}
    - user: geekotest

{% macro scriptgen(prj) -%}
{{ prj }}:
  file.directory:
    - name: {{ dir }}{{ prj }}
    - user: geekotest

  cmd.run:
    - name: su geekotest -c 'python3 script/scriptgen.py {{ prj }}'
    - cwd: {{ dir }}
    - onchanges_any:
      - file: {{ dir }}{{ prj }}
      - git: git@github.com:os-autoinst/openqa-trigger-from-obs.git
      - git: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs-plugin
{%- endmacro %}

# SLES 16.0 Quarterly Updates
{{ scriptgen('SUSE:SLFO:Products:SLES:16.0:TEST') }}

# SLES 15-SP7 Quarterly Updates
{{ scriptgen('SUSE:SLE-15-SP7:Update:QR:TEST') }}

# SLES 15-SP4 RT
{{ scriptgen('SUSE:SLE-15-SP4:Update:Products:SLERT') }}

# Agama development
{{ scriptgen('Devel:YaST:Agama:Head') }}

# BCI repo trigger
{{ scriptgen('SUSE:SLE-15-SP6:Update:BCI') }}
{{ scriptgen('SUSE:SLE-15-SP7:Update:BCI') }}
