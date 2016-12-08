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
{% for i in range(pillar['workerconf'][grains['host']]['numofworkers'])
     for network in range(0, 3)
       tapdevices.append(i+network*64)
     end
   end %}

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
      - OVS_BRIDGE_PORT_DEVICE_1='tap0'
      - OVS_BRIDGE_PORT_DEVICE_2='tap1'
      - OVS_BRIDGE_PORT_DEVICE_3='tap2'
      - OVS_BRIDGE_PORT_DEVICE_4='tap3'
      - OVS_BRIDGE_PORT_DEVICE_5='tap4'
      - OVS_BRIDGE_PORT_DEVICE_6='tap5'
      - OVS_BRIDGE_PORT_DEVICE_8='tap64'
      - OVS_BRIDGE_PORT_DEVICE_9='tap65'
      - OVS_BRIDGE_PORT_DEVICE_10='tap66'
      - OVS_BRIDGE_PORT_DEVICE_11='tap67'
      - OVS_BRIDGE_PORT_DEVICE_12='tap68'
      - OVS_BRIDGE_PORT_DEVICE_13='tap69'
      - OVS_BRIDGE_PORT_DEVICE_15='tap128'
      - OVS_BRIDGE_PORT_DEVICE_16='tap129'
      - OVS_BRIDGE_PORT_DEVICE_17='tap130'
      - OVS_BRIDGE_PORT_DEVICE_18='tap131'
      - OVS_BRIDGE_PORT_DEVICE_19='tap132'
      - OVS_BRIDGE_PORT_DEVICE_20='tap133'
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
