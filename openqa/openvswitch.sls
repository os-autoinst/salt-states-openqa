# https://github.com/os-autoinst/openQA/blob/master/docs/Networking.asciidoc

{%- if not grains.get('noservices', False) %}
openvswitch:
  service.running:
    - enable: True
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br1
{%- endif %}

wicked:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

{%- if not grains.get('noservices', False) %}
wicked ifup br1:
  cmd.run:
    - onchanges:
      - file: /etc/sysconfig/network/ifcfg-br1
{%- endif %}

{% set tapdevices = [] %}
{% for i in range(pillar['workerconf'].get(grains['host'], {}).get('numofworkers', 0)) %}
{%   for network in range(0, 3) %}
{%      do tapdevices.append(i+network*64) %}
{%     endfor %}
{%  endfor %}

# Will create a list "multihostworkers" of all multi-host workers to be connected over GRE tunnel(s)
# Those hosts are identified by WORKER_CLASS value from pillar defined in "multihostclass" variable
# Only one class is supported and its name have to be unique - will match also the strings that contain it!
{% set multihostclass = 'tap' %}
{% set multihostworkers = [] %}
{% for host in pillar['workerconf'] %}
{%   if 'global' in pillar['workerconf'][host] %}
{%     if multihostclass in pillar['workerconf'][host]['global']['WORKER_CLASS'] | default('undefined') %}
{%       do multihostworkers.append(host) %}
{%     endif %}
{%   endif %}
# The class can be defined in both places (global X numbered workers) at the same time
{%   if 'workers' in pillar['workerconf'][host] %}
{%     for wnum in pillar['workerconf'][host]['workers'] %}
{%       if multihostclass in pillar['workerconf'][host]['workers'][wnum]['WORKER_CLASS'] | default('undefined') %}
{%         do multihostworkers.append(host) %}
{%       endif %}
{%     endfor %}
{%   endif %}
{% endfor %}
# Remove duplicate entries and sort them in the list
{% set multihostworkers = multihostworkers | unique | sort | list %}

# Make openvswitch bridge br1 persistant
/etc/sysconfig/network/ifcfg-br1:
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - contents:
      - BOOTPROTO='static'
      - IPADDR='10.0.2.2/15'
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
    - mode: "0644"
    - contents:
      - BOOTPROTO='none'
      - IPADDR=''
      - NETMASK=''
      - PREFIXLEN=''
      - STARTMODE='hotplug'
      - TUNNEL='tap'
      - TUNNEL_SET_GROUP='kvm'
      - TUNNEL_SET_OWNER='_openqa-worker'
    - require:
      - pkg: worker.packages
{% endfor %}

# Worker for GRE needs to have defined entry bridge_ip: <uplink_address_of_this_worker> in pillar data
/etc/wicked/scripts/gre_tunnel_preup.sh:
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
      - action="$1"
      - bridge="$2"
      - '# enable STP for the multihost bridges'
      - ovs-vsctl set bridge $bridge stp_enable=true
      - for gre_port in $(ovs-vsctl list-ifaces $bridge | grep gre) ; do ovs-vsctl --if-exists del-port $bridge $gre_port ; done
     {% for remote in otherworkers %}
     {%     set remote_conf = pillar['workerconf'][remote] %}
     {%     if 'bridge_ip' in remote_conf %}
     {%         set remote_ip = remote_conf['bridge_ip'] %}
     {%     elif 'bridge_iface' in remote_conf %}
     {%         set remote_interfaces = salt.mine.get("host:" + remote, 'ip4_interfaces', tgt_type='grain').values()|list %}
     {%         set remote_bridge_interface = remote_conf['bridge_iface'] %}
     {%         if remote_interfaces|length > 0 and remote_bridge_interface in remote_interfaces[0] %}
     {%             set remote_ip = remote_interfaces[0][remote_bridge_interface][0] %}
     {%         endif %}
     {%     endif %}
     {% if remote_ip is defined and remote_ip|length %}
      - ovs-vsctl --may-exist add-port $bridge gre{{- loop.index }} -- set interface gre{{- loop.index }} type=gre options:remote_ip={{ remote_ip }}
     {% endif %}
     {% endfor %}
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

{%- if not grains.get('noservices', False) %}
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
      - file: /etc/wicked/scripts/gre_tunnel_preup.sh
{%- endif %}
