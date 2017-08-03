# slenkins and autoyast use Open vSwitch for it's tap devices and such
openvswitch:
  service.running:
    - enable: True
    - require:
      - file: /etc/systemd/system/openvswitch.service
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br1

wicked ifup br1:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br1

# Remove old openvswitch systemd override
/etc/systemd/system/openvswitch.service:
  file.absent:
    - require:
      - pkg: worker.packages

{% set tapdevices = [] %}
{% for i in range(pillar['workerconf'][grains['host']]['numofworkers']) %}
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
{%   if 'workers' in pillar['workerconf'][host] %}
{%    for wnum in pillar['workerconf'][host]['workers'] %}
{%      if multihostclass in pillar['workerconf'][host]['workers'][wnum]['WORKER_CLASS'] %}
{%        do multihostworkers.append(host) if host not in multihostworkers %}
{%      endif %}
{%    endfor %}
{%   endif %}
{% endfor %}

# Make openvswitch bridge br1 persistant
/etc/sysconfig/network/ifcfg-br1:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='static'
      - IPADDR='10.0.2.2/15'
      - STARTMODE='auto'
      - OVS_BRIDGE='yes'
      - COOLOTEST='1'
     {% for i in tapdevices %}
      - OVS_BRIDGE_PORT_DEVICE_{{ i }}='tap{{ i }}'
     {% endfor %}
     {% if grains['host'] in multihostworkers and multihostworkers|length > 1 %}
      - PRE_UP_SCRIPT="wicked:gre_tunnel_preup.sh"
     {% endif %}
    - require:
      - pkg: worker-openqa.packages

# Configure tap devices for openvswitch

{% for i in tapdevices %}
/etc/sysconfig/network/ifcfg-tap{{ i }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='none'
      - IPADDR=''
      - NETMASK=''
      - PREFIXLEN=''
      - STARTMODE='auto'
      - TUNNEL='tap'
      - TUNNEL_SET_GROUP='kvm'
      - TUNNEL_SET_OWNER='_openqa-worker'
    - require:
      - pkg: worker-openqa.packages
{% endfor %}

{% if grains['host'] in multihostworkers and multihostworkers|length > 1 %}
{%   set otherworkers = multihostworkers %}
{%   do otherworkers.remove(grains['host']) %}
/etc/wicked/scripts/gre_tunnel_preup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 744
    - makedirs: true
    - contents:
      - '#!/bin/sh'
      - action="$1"
      - bridge="$2"
      - '# enable STP for the multihost bridges'
      - ovs-vsctl set bridge $bridge stp_enable=true
     {% for remote in otherworkers %}
      - ovs-vsctl --may-exist add-port $bridge gre{{- loop.index }} -- set interface gre{{- loop.index }} type=gre options:remote_ip={{ pillar['workerconf'][remote]['bridge_ip'] }}
     {% endfor %}
{% endif %}

# Configure os-autoinst-openvswitch bridge configuration file
/etc/sysconfig/os-autoinst-openvswitch:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - OS_AUTOINST_USE_BRIDGE='br1'
    - require:
      - pkg: worker-openqa.packages

# Enable os-autoinst-openvswitch helper
os-autoinst-openvswitch:
  service.running:
    - enable: True
    - require:
      - file: /etc/sysconfig/os-autoinst-openvswitch
      - file: /etc/sysconfig/network/ifcfg-br1

#TODO - setup openvswitch GRE tunnel between workers for slenkins and autoyast tests
# https://github.com/os-autoinst/openQA/blob/master/docs/Networking.asciidoc
