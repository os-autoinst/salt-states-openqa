# MTU for this network is 1360 bytes
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
        MTU: "1500"
{%- else %}
{%- set nm_conn = salt['cmd.run']('nmcli -g GENERAL.CONNECTION device show ' ~ def_iface) %}
  cmd.run:
    - name: nmcli connection modify "{{ nm_conn }}" 802-3-ethernet.mtu 1500
{%- endif %}
{%- endif %}
