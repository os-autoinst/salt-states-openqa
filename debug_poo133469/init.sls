{% set minion_cmd_path = salt['cmd.shell']('rpm -ql python3-salt | grep "salt/minion.py"') %}

patch:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5

{% if not opts['test'] %}
minion_cmd_file:
  file.patch:
    - name: {{ minion_cmd_path }}
    - source: salt://debug_poo133469/minion.patch
{% endif %}
