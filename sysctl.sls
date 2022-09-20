# For all other remotely managed machines we want automatic reboots on kernel
# panics to restore services
# https://docs.kernel.org/admin-guide/sysctl/kernel.html#panic recommends 60
# if soft_watchdog=1
{%- if not grains.get('noservices', False) %}
kernel.panic:
  sysctl.present:
    - value: 60
{%- endif %}
