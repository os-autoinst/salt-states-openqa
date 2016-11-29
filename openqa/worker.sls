{% if 'Tumbleweed' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/" + grains['osrelease'] %}
{% set opensuserepopath = "openSUSE_Leap_" + grains['osrelease'] %}
{% elif 'Enterprise' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set opensuserepopath = "SLE_12_SP1" %}
{% else %}
{% set opensuserepopath = "openSUSE_" + grains['osrelease'] %}
{% endif %}
openQA:
  pkgrepo.managed:
    - humanname: openQA ({{ opensuserepopath }})
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/{{ opensuserepopath }}/
    - gpgcheck: False
    - refresh: True

{% if 'Leap 42.1' in grains['oscodename'] %}
# Latest kernel needed to avoid nvme issues
kernel_stable:
  pkgrepo.managed:
    - humanname: Kernel Stable
    - baseurl: http://download.opensuse.org/repositories/Kernel:/stable/standard/
    - gpgcheck: False
    - refresh: True
{% endif %}

kernel-default:
  pkg.installed:
    - refresh: True
    - version: '>=4.4' # needed to fool zypper into the vendor change
    {% if 'Leap 42.1' in grains['oscodename'] %}
    - fromrepo: kernel_stable
    {% endif %}

{% if openqamodulesrepo %}
openQA-modules:
  pkgrepo.managed:
    - humanname: openQA Modules ({{ opensuserepopath }})
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/{{ openqamodulesrepo }}/{{ opensuserepopath }}/
    - gpgcheck: False
    - refresh: True
{% endif %}

# Packages that must come from the openQA repo
worker-openqa.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - openQA-worker
      - xterm-console
      - freeipmi
      - os-autoinst-openvswitch
    - fromrepo: openQA
    - require:
      - pkg: kernel-default
      {% if 'Enterprise' in grains['oscodename'] %}
      - pkgrepo: openQA-modules
      {% endif %}

# Packages that can come from anywhere
worker.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - x3270 # for s390x backend
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - xdotool # for ssh-x
      - qemu-ovmf-x86_64 # for UEFI
      - ipmitool # for ipmi backend and generalhw
      - net-snmp # for generalhw backend
      - libcap-progs # for TAPSCRIPT
      - bridge-utils # for TAPSCRIPT and TAP support
      - openvswitch-switch # for TAP support
      - SuSEfirewall2 # For TAP support and for other good reasons
      - qemu: '>=2.3'
      - atop
      - perl-XML-Writer # for virtualization tests
    - require:
      - pkg: worker-openqa.packages

# Ensure NFS share is mounted and setup on boot
/var/lib/openqa/share:
  mount.mounted:
    - device: {{ pillar['workerconf']['nfspath'] }}
    - fstype: nfs
    - opts: ro
    - require:
      - pkg: worker-openqa.packages

## setup workers.ini based on info in workerconf pillar
## pillar must contain the following
# workerconf:
#   openqahost: [hostname of openQA WebUI/scheduler server]
#
#     [hostname of worker server]:
#       numofworkers: [number of workers]
#       client_key: [Client API Key]
#       client_secret: [Client API Secret]
#       workers:
#         [number of worker instance]:
#           [workers.ini key]: [workers.ini value]
#           [workers.ini key]: [workers.ini value]
#         [number of worker instance]:
#           [workers.ini key]: [workers.ini value]
#
#     [hostname of worker server]:
#       numofworkers: [number of workers]
#       client_key: [Client API Key]
# etc ...
## example pillar
# workerconf:
#   openqahost: openqa.opensuse.org
#
#   openqaworker1:
#     numofworkers: 16
#     client_key: BLAHBLAHBLAH
#     client_secret: BLAHBLAHBLAH
#     workers: # Config for each worker instance goes here
#       1:
#         WORKER_CLASS: qemu_x86_64
##
/etc/openqa/workers.ini:
  file.managed:
    - source:
      - salt://openqa/workers.ini
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - defaults:
      global:
        HOST: http://{{ pillar['workerconf']['openqahost'] }}
        WORKER_HOSTNAME: {{ grains['fqdn_ip4'][0] }}
    - context:
      {% set workerhost = grains['host'] %}
      {% set workerdict = pillar.get('workerconf', {})[workerhost].get('workers', {}) %}
      workers: {{ workerdict }}
    - require:
      - pkg: worker-openqa.packages

# setup client.conf based on info in workerconf pillar
/etc/openqa/client.conf:
  ini.sections_present:
    - sections:
        {{ pillar['workerconf']['openqahost'] }}:
          key: {{ pillar['workerconf'][grains['host']]['client_key'] }}
          secret: {{ pillar['workerconf'][grains['host']]['client_secret'] }}
    - require:
      - pkg: worker-openqa.packages

# start services based on numofworkers set in workerconf pillar
{% for i in range(pillar['workerconf'][grains['host']]['numofworkers']) %}
{% set i = i+1 %}
openqa-worker@{{ i }}:
  service.running:
    - enable: True
    - require:
      - pkg: worker-openqa.packages
    - watch:
      - file: /etc/openqa/workers.ini
{% endfor %}

openqa-worker.target:
  service.running:
    - enable: True
    - require:
      - pkg: worker-openqa.packages

# Configure firewall and watch on SuSEfirewall2 conf change
SuSEfirewall2:
  service.running:
    - enable: True
    - watch:
      - file: /etc/sysconfig/SuSEfirewall2
    - require:
      - pkg: worker.packages

# os-autoinst needs to upload logs to rather random ports and ovs needs configuration
/etc/sysconfig/SuSEfirewall2:
  file.managed:
    - template: jinja
    - source: salt://openqa/SuSEfirewall2.conf

# os-autoinst starts local Xvnc with xterm and ssh - apparmor's chains are too strict for that
apparmor:
  service.dead:
    - enable: False

# TAPSCRIPT requires qemu to be able have the CAP_NET_ADMIN capability - Denis to investigate moving to openvswitch
setcap cap_net_admin=ep /usr/bin/qemu-system-{{ grains['osarch'] }}:
  cmd.run:
    - unless: getcap /usr/bin/qemu-system-{{ grains['osarch'] }} | grep -q 'cap_net_admin+ep'
    - require:
      - pkg: worker.packages

# TAPSCRIPT requires _openqa-worker to be able to sudo
/etc/sudoers.d/_openqa-worker:
  file.managed:
    - mode: 600
    - contents:
      - '_openqa-worker ALL=(ALL) NOPASSWD: ALL'


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
{% for i in [0,1,2,3,4,5,64,65,66,67,68,69,128,129,130,131,132,133] %}
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


