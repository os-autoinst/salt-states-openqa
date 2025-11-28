{% set postgres_module_path = salt['cmd.run']('find /usr/lib/python* -name postgres.py -path "*/salt/modules/*" 2>/dev/null', python_shell=True) %}

patch:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5

mitigation_poo189027_privileges_map:
  file.patch:
    - name: {{ postgres_module_path }}
    - source: salt://debug_poo189027/postgres.patch
