geekotest:
  user:
    - present

{% set dir = '/opt/openqa-trigger-from-ibs/' %}
{% set script_test = '[[ -f print_openqa.sh && -f print_rsync_iso.sh && -f print_rsync_repo.sh && -f read_files.sh ]]' %}
{{ dir }}:
  file.directory:
    - name: {{ dir }}
    - user: geekotest

openqa-trigger-from-ibs:
  pkg.installed:
    - refresh: False
    - pkgs:
      - git
      - python3

  git.latest:
    - name: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs
    - target: {{ dir }}
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
