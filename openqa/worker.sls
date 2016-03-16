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
    - fromrepo: openQA

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
      - bridge-utils # for TAPSCRIPT
      - tunctl # for TAP support
      - qemu: '>=2.3'

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
      {% set workerdict = pillar.get('workerconf', {})[workerhost]['workers'] %}
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

# os-autoinst needs to upload logs to rather random ports
SuSEfirewall2:
  service.dead:
    - enable: False

# os-autoinst starts local Xvnc with xterm and ssh - apparmor's chains are too strict for that
apparmor:
  service.dead:
    - enable: False

# TAPSCRIPT requires qemu to be able have the CAP_NET_ADMIN capability
setcap cap_net_admin=ep /usr/bin/qemu-system-{{ grains['osarch'] }}:
  cmd.run:
    - unless: getcap /usr/bin/qemu-system-{{ grains['osarch'] }} | grep -q 'cap_net_admin+ep'
    - require:
      - pkg: worker.packages

# Setup 10 old fashioned tap devices for use by slenkins and autoyast tests - deprecated, encorage move to TAPSCRIPT
{% for i in range(10) %}
/etc/wicked/ifconfig/tap{{ i }}.xml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
      <!-- /etc/wicked/ifconfig/tap{{ i }}.xml -->
      <interface>
        <name>tap{{ i }}</name>
        <tap>
          <owner>_openqa-worker</owner>
        </tap>
      </interface>
    - require:
      - pkg: worker-openqa.packages
{% endfor %}
