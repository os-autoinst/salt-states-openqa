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
  file.directory:
    - name: {{ dir }}{{ prj }}
    - user: geekotest

  cmd.run:
    - name: su geekotest -c 'python3 script/scriptgen.py {{ prj }}'
    - cwd: {{ dir }}
    - onchanges_any:
      - file: {{ dir }}{{ prj }}
      - git: https://github.com/os-autoinst/openqa-trigger-from-obs
      - git: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs-plugin
{%- endmacro %}

{{ scriptgen('SUSE:SLE-15-SP7:GA:TEST') }}

{% for i in ['A','B','C','D','E','F','G','H','S','Y','V'] %}
{{ scriptgen('SUSE:SLE-15-SP7:GA:Staging:' + i) }}
{% endfor %}

# SLE 16.0/SL-Micro 6.2 Stagings
{% for i in ['A','B','C','D','E','F','G','H','I','J','K','L','M','S','V','Y'] %}
{{ scriptgen('SUSE:SLFO:Main:Staging:' + i) }}
{% endfor %}

# SL Micro 6.0 Staging Updates (Maintenance)
{% for i in ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'] %}
{{ scriptgen('SUSE:ALP:Source:Standard:1.0:Staging:' + i) }}
{% endfor %}

# SL Micro 6.1 Staging Updates (Maintenance)
{% for i in ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'] %}
{{ scriptgen('SUSE:SLFO:1.1:Staging:' + i) }}
{% endfor %}

# SLFO Kernel Staging Updates (Maintenance)
{% for i in ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'] %}
{{ scriptgen('SUSE:SLFO:Kernel:1.0:Staging:' + i) }}
{% endfor %}

{{ scriptgen('SUSE:SLE-15-SP7:Update:WSL') }}
{{ scriptgen('SUSE:SLFO:Products:SL-Micro:6.2:ToTest') }}
{{ scriptgen('SUSE:SLFO:Products:SLES:16.0:TEST') }}
{{ scriptgen('SUSE:SLFO:Products:SLES:16.1:TEST') }}
{{ scriptgen('SUSE:SLE-15-SP7:Update:QR:TEST') }}
{{ scriptgen('SUSE:SLE-15-SP6:Update:BCI') }}
{{ scriptgen('SUSE:SLE-15-SP7:Update:BCI') }}
{{ scriptgen('SUSE:SLE-15-SP4:Update:Products:SLERT') }}
# SL Micro 6.0 Increments
{{ scriptgen('SUSE:ALP:Products:Marble:6.0:ToTest') }}
# SL Micro 6.1 Increments
{{ scriptgen('SUSE:SLFO:Products:SL-Micro:6.1:ToTest') }}
{{ scriptgen('Devel:YaST:Agama:Head') }}
