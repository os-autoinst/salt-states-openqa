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

{% if grains.get('roles') == 'worker' and grains['host'] in pillar['workerconf'].keys() %}
{% set bond_slave_ifaces = pillar['workerconf'][grains['host']].get('bond_slave_ifaces', []) %}
{% set bridge_iface = pillar['workerconf'][grains['host']].get('bridge_iface') %}
{% if bond_slave_ifaces and bridge_iface %}
{% for bond_slave_iface in bond_slave_ifaces %}
/etc/sysconfig/network/ifcfg-{{ bond_slave_iface }}:
  file.managed:
    - contents: |
        BOOTPROTO='none'
        STARTMODE='hotplug'
{% endfor %}
/etc/sysconfig/network/ifcfg-{{ bridge_iface }}:
  file.managed:
    - contents: |
        BOOTPROTO='dhcp'
        STARTMODE='auto'
        BONDING_MASTER='yes'
        {%- for bond_slave_iface in bond_slave_ifaces %}
        BONDING_SLAVE{{ loop.index0 }}='{{ bond_slave_iface }}'
        {%- endfor %}
        BONDING_MODULE_OPTS='mode=active-backup miimon=100'
{% endif %}
{% endif %}
