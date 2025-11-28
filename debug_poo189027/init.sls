patch:
  pkg.installed:
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5

mitigation_poo189027_privileges_map:
  file.patch:
    - name: /usr/lib/python3.6/site-packages/salt/modules/postgres.py
    - source: salt://debug_poo189027/postgres.patch
