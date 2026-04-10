# https://github.com/os-autoinst/openQA/blob/master/docs/Networking.asciidoc

{%- set backend = grains.get('network_backend', 'wicked') %}
{%- set noservices = grains.get('noservices', False) %}
{%- if backend == 'NetworkManager' %}
  {%- set gre_tunnel_script_path = '/etc/NetworkManager/dispatcher.d/gre_tunnel_preup.sh' %}
{%- else %}
  {%- set gre_tunnel_script_path = '/etc/wicked/scripts/gre_tunnel_preup.sh' %}
{%- endif %}

{%- if not noservices %}
openvswitch:
  service.running:
    - enable: True
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br1

reload_network_on_script_change:
  cmd.run:
    - name: {% if backend == 'wicked' %}wicked ifup all{% else %}nmcli connection up br1{% endif %}
    - onchanges_any:
      - file: /etc/sysconfig/network/ifcfg-br1
      - file: {{ gre_tunnel_script_path }}

# Ensure forwarding of traffic for the bridge:
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1
net.ipv4.conf.br1.forwarding:
  sysctl.present:
    - value: 1
{%- if 'bridge_iface' in pillar['workerconf'][grains['host']].keys() %}
net.ipv4.conf.{{ pillar['workerconf'][grains['host']]['bridge_iface'] }}.forwarding:
  sysctl.present:
    - value: 1
{%- endif %}
{%- endif %}

{{ backend }}:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# Add 3 tap devices per worker slot; pretend there is one more worker slot to have one more set of tap devices for debugging
{% set tapdevices = [] %}
{% for i in range(pillar['workerconf'].get(grains['host'], {}).get('numofworkers', 0) + 1) %}
{%   for network in range(0, 3) %}
{%      do tapdevices.append(i+network*64) %}
{%     endfor %}
{%  endfor %}

{%- if not noservices %}
# See https://progress.opensuse.org/issues/151310
ovs-vsctl set int br1 mtu_request=1460:
  cmd.run:
    - unless: 'ovs-vsctl get int br1 mtu_request | grep -q 1460'
{%- endif %}

# Create list "multihostworkers" of all multi-host workers to be connected over GRE tunnel(s)
{% set multihostworkers = salt['gre_peers.compute'](grains['host'], pillar['workerconf']) | unique | sort | list %}

# Make openvswitch bridge br1 persistant
/etc/sysconfig/network/ifcfg-br1:
  file.managed:
    - user: root
    - group: root
    - contents:
      - BOOTPROTO='static'
      - IPADDR='10.0.2.2/15'
      - IPADDR_1='fec0::2/63'
      - STARTMODE='auto'
      - OVS_BRIDGE='yes'
     {% for i in tapdevices %}
      - OVS_BRIDGE_PORT_DEVICE_{{ i }}='tap{{ i }}'
     {% endfor %}
     {% if grains['host'] in multihostworkers and multihostworkers|length > 1 %}
      - PRE_UP_SCRIPT="wicked:gre_tunnel_preup.sh"
     {% endif %}
    - require:
      - pkg: worker.packages

# Configure tap devices for openvswitch

{% for i in tapdevices %}
/etc/sysconfig/network/ifcfg-tap{{ i }}:
  file.managed:
    - user: root
    - group: root
    - contents:
      - BOOTPROTO='none'
      - IPADDR=''
      - NETMASK=''
      - PREFIXLEN=''
      - STARTMODE='hotplug'
      - TUNNEL='tap'
      - TUNNEL_SET_GROUP='kvm'
      - TUNNEL_SET_OWNER='_openqa-worker'
      - ZONE=trusted
    - require:
      - pkg: worker.packages
{% endfor %}

# Worker for GRE needs to have defined entry bridge_ip: <uplink_address_of_this_worker> in pillar data
{{ gre_tunnel_script_path }}:
{% if grains['host'] in multihostworkers and multihostworkers|length > 1 %}
{%   set otherworkers = multihostworkers %}
{%   do otherworkers.remove(grains['host']) %}
  file.managed:
    - user: root
    - group: root
    - mode: "0744"
    - makedirs: true
    - contents:
      - '#!/bin/sh'
      - OVS_CMD=$(command -v ovs-vsctl)
      - if [ -z "$OVS_CMD" ]; then
      -     'logger -- "Error: ovs-vsctl not found. Skipping script $0"'
      -     exit 0 # Exit 0 to avoid breaking NetworkManager's flow
      - fi
      - TARGET_BRIDGE=$("$OVS_CMD" list-br) # We expect only one Open-vSwitch bridge to be present
      - '# NM_DISPATCHER_ACTION env var is set when NM calls scripts via dispatcher service'
      - '# Ref: https://networkmanager.dev/docs/api/1.44.4/NetworkManager-dispatcher.html'
      - '# 2. Argument Normalization (NetworkManager vs. wicked)'
      - '# NetworkManager: $1 = interface name, $2 = action'
      - '# wicked: $1 = action, $2 = interface name'
      - if [ -n "$NM_DISPATCHER_ACTION" ]; then
      -     '# Environment detected as NetworkManager'
      -     bridge="$1"
      -     action="$2"
      - else
      -     '# Environment detected as wicked'
      -     action="$1"
      -     bridge="$2"
      - fi
      - if "$OVS_CMD" list-br | grep -qx "$bridge"; then
      - if [ "$action" = "pre-up" ] || [ "$action" = "up" ]; then
      -     '# enable STP for the multihost bridges'
      -     ovs-vsctl set bridge $bridge stp_enable=false
      -     ovs-vsctl set bridge $bridge rstp_enable=true
      - for gre_port in $(ovs-vsctl list-ifaces $bridge | grep gre) ; do ovs-vsctl --if-exists del-port $bridge $gre_port ; done
     {%- for remote in otherworkers -%}
     {%-     set remote_conf = pillar['workerconf'][remote] -%}
     {%-     if 'bridge_ip' in remote_conf -%}
     {%-         set remote_ip = remote_conf['bridge_ip'] -%}
     {%-     elif 'bridge_iface' in remote_conf -%}
     {%-         set remote_interfaces = salt.mine.get("host:" + remote, 'ip4_interfaces', tgt_type='grain').values()|list -%}
     {%-         set remote_bridge_interface = remote_conf['bridge_iface'] -%}
     {%-         if remote_interfaces|length > 0 and remote_bridge_interface in remote_interfaces[0] -%}
     {%-             set remote_ip = remote_interfaces[0][remote_bridge_interface][0] -%}
     {%-         endif -%}
     {%-     endif -%}
     {% if remote_ip is defined and remote_ip|is_ip %}
      -     'ovs-vsctl --may-exist add-port $bridge gre{{- loop.index }} -- set interface gre{{- loop.index }} type=gre options:remote_ip={{ remote_ip }} # {{ remote }}'
     {%- else -%}
     {% do salt.log.warning("remote: \"" + remote + "\" found in workerconf.sls but not in salt mine, host currently offline?") %}
      -     '#ovs-vsctl --may-exist add-port $bridge gre{{- loop.index }} -- set interface gre{{- loop.index }} type=gre options:remote_ip= # {{ remote }} (offline at point of file generation)'
     {%- endif -%}
     {% endfor %}
      - fi
      - fi
{% else %}
  file.absent
{% endif %}

# Configure os-autoinst-openvswitch bridge configuration file
/etc/sysconfig/os-autoinst-openvswitch:
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - contents:
      - OS_AUTOINST_USE_BRIDGE='br1'
    - require:
      - pkg: worker.packages

/etc/systemd/system/os-autoinst-openvswitch.service.d/30-init-timeout.conf:
  file.managed:
    - name: /etc/systemd/system/os-autoinst-openvswitch.service.d/30-init-timeout.conf
    - mode: "0644"
    - source: salt://openqa/os-autoinst-openvswitch-init-timeout.conf
    - makedirs: true

{%- if not noservices %}
openvswitch override reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/os-autoinst-openvswitch.service.d/30-init-timeout.conf

# Enable os-autoinst-openvswitch helper or restart it if ifcfg-br1 and/or gre_tunnel_preup.sh has changed
os-autoinst-openvswitch:
  service.running:
    - enable: True
    - require:
      - file: /etc/sysconfig/os-autoinst-openvswitch
    - onchanges_any:
      - file: /etc/sysconfig/network/ifcfg-br1
      - file: {{ gre_tunnel_script_path }}
{%- endif %}
