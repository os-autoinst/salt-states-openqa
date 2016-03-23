openQA:
  pkgrepo.managed:
    - humanname: openQA (Leap 42.1)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/openSUSE_Leap_42.1/
    - gpgcheck: 0
    - autorefresh: 1

# Latest kernel needed to avoid nvme issues
kernel_stable:
  pkgrepo.managed:
    - humanname: Kernel Stable
    - baseurl: http://download.opensuse.org/repositories/Kernel:/stable/standard/
    - gpgcheck: 0
    - autorefresh: 1

kernel-default:
  pkg.installed:
    - refresh: 1
    - version: '>=4.4' # needed to fool zypper into the vendor change
    - fromrepo: kernel_stable

# Packages that must come from the openQA repo
worker-openqa.packages:
  pkg.installed:
    - refresh: 1
    - pkgs:
      - openQA-worker
      - xterm-console
      - freeipmi
      - os-autoinst-openvswitch
    - fromrepo: openQA
    - require:
      - pkg: kernel-default

# Packages that can come from anywhere
worker.packages:
  pkg.installed:
    - refresh: 1
    - pkgs:
      - x3270 # for s390x backend
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - qemu-ovmf-x86_64 # for UEFI
      - ipmitool # for ipmi backend and generalhw
      - net-snmp # for generalhw backend
      - libcap-progs # for TAPSCRIPT
      - bridge-utils # for TAPSCRIPT and TAP support
      - openvswitch-switch # for TAP support
      - SuSEfirewall2 # For TAP support and for other good reasons
      - qemu: '>=2.3'
    - require:
      - pkg: worker-openqa.packages

# Ensure NFS share is mounted and setup on boot
/var/lib/openqa/share:
  mount.mounted:
    - device: '{{ pillar['workerconf']['openqahost'] }}:/var/lib/openqa/share'
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

# slenkins and autoyast use Open vSwitch for it's tap devices and such
openvswitch:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/system/openvswitch.service
    - require:
      - file: /etc/systemd/system/openvswitch.service

# openvswitch needs to start before the network as documented https://en.opensuse.org/Portal:Wicked/OpenvSwitch
/etc/systemd/system/openvswitch.service:
  file.managed:
    - source:
      - salt://openqa/openvswitch.service
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
    - require:
      - pkg: worker-openqa.packages

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


