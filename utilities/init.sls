utilities.packages:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - git-core  # not present on machines of all roles anyways
        - retry  # to have the ability to retry things without failing
        - smartmontools  # to check SMART values of disks

# Used by default, ensure consistent use, see poo#189798
polkit:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
{%- if not grains.get('noservices', False) %}
  service.enabled:
    - name: polkit
{%- endif %}
