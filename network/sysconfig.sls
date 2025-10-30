{% set worker_netconf = pillar['network_sysconfig'].get(grains['fqdn'], {}) %}

{% for netconf_name in worker_netconf.keys() %}
{% set netconf = worker_netconf[netconf_name] %}
/etc/sysconfig/network/{{ netconf_name }}:
  file.keyvalue:
    - append_if_not_found: True
    - seperator: '='
    - key_values:
{%- for config in netconf %}
  {%- set config_key, config_value = (config.items() | list)[0] %}
        {{ config_key }}: {{ config_value }}
{%- endfor -%}
{% endfor %}
