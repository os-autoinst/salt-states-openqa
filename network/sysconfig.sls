{% set worker_netconf = pillar['network_sysconfig'].get(grains['fqdn'], {}) %}
{% set backend = grains.get('network_backend', 'wicked') %}

{%- if backend == 'wicked' %}
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
{%- endif %}

{% if grains.get('roles') == 'worker' and grains['host'] in pillar['workerconf'].keys() %}
{% set bond_slave_ifaces = pillar['workerconf'][grains['host']].get('bond_slave_ifaces', []) %}
{% set bridge_iface = pillar['workerconf'][grains['host']].get('bridge_iface') %}
{% if bond_slave_ifaces and bridge_iface %}
{% for bond_slave_iface in bond_slave_ifaces %}
{%- if backend == 'wicked' %}
/etc/sysconfig/network/ifcfg-{{ bond_slave_iface }}:
  file.managed:
    - contents: |
        BOOTPROTO='none'
        STARTMODE='hotplug'
{%- else %}
{% set nmconn_uuid = salt['cmd.run']('uuidgen --sha1 --namespace @dns --name ' ~ bond_slave_iface) %}
/etc/NetworkManager/system-connections/{{ bridge_iface }}-{{ bond_slave_iface }}.nmconnection:
  file.managed:
    - user: root
    - mode: '0600'
    - contents: |
        [connection]
        id={{ bridge_iface }}-{{ bond_slave_iface }}
        uuid={{ nmconn_uuid }}
        type=ethernet
        controller={{ bridge_iface }}
        interface-name={{ bond_slave_iface }}
        port-type=bond
{%- endif %}
{% endfor %}
{%- if backend == 'wicked' %}
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
{%- else %}
{% set bond_uuid = salt['cmd.run']('uuidgen --sha1 --namespace @dns --name ' ~ bridge_iface) %}
/etc/NetworkManager/system-connections/{{ bridge_iface }}.nmconnection:
  file.managed:
    - user: root
    - mode: '0600'
    - contents: |
        [connection]
        id={{ bridge_iface }}
        uuid={{ bond_uuid }}
        type=bond
        interface-name={{ bridge_iface }}

        [bond]
        miimon=100
        mode=active-backup

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=eui64
        ip6-privacy=0
        method=auto
{% endif %}
{% endif %}
{% endif %}
