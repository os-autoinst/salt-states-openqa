# slenkins and autoyast use Open vSwitch for it's tap devices and such
openvswitch:
  service.running:
    - enable: True
    - require:
      - file: /etc/systemd/system/openvswitch.service

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
     {% for i in tapdevices %}
      - OVS_BRIDGE_PORT_DEVICE_1='tap{{ i }}'
     {% endfor %}
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
