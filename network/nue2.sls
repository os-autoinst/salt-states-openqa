# Configure the defined MTU on the default network interface
# and reload the network if MTU is changed
{%- set mtu_value = "1500" %}
{%- set backend = grains.get('network_backend', 'wicked') %}
{%- set def_iface = grains.get('default_interface', none) %}
{%- if def_iface is not none %}
network_mtu:
{%- if backend == 'wicked' %}
  file.keyvalue:
    - name: /etc/sysconfig/network/ifcfg-{{ def_iface }}
    - append_if_not_found: True
    - separator: '='
    - key_values:
        MTU: {{ mtu_value }}
{%- else %}
{%- set nm_conn = grains.get('default_nmconnection', none) %}
{%- if nm_conn is not none %}
  ini.options_present:
    - name: /etc/NetworkManager/system-connections/{{ nm_conn }}.nmconnection
    - sections:
        ethernet:
          mtu: {{ mtu_value }}
{%- endif %}
{%- endif %}
reload_network_on_mtu_change:
  cmd.run:
    - name: {% if backend == 'wicked' %}wicked ifup all{% else %}nmcli connection reload{% endif %}
    - onchanges:
      - {% if backend == 'wicked' %}file{% else %}ini{% endif %}: network_mtu
{%- endif %}
