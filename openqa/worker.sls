{% if 'Tumbleweed' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/" + grains['osrelease'] %}
{% set opensuserepopath = "openSUSE_Leap_" + grains['osrelease'] %}
{% elif 'SP1' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set opensuserepopath = "SLE_12_SP1" %}
{% elif 'SP2' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set opensuserepopath = "SLE_12_SP2" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set opensuserepopath = "SLE_12_SP3" %}
{% elif 'aarch64' in grains['cpuarch'] %}
{% set opensuserepopath = "SLE_12" %}
{% set opensusemodulesrepo = "SLE_12_SP2" %}
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

{% if 'aarch64' in grains['osarch'] %}
# Use sp3 QEMU for aarch64 since we won't salt overdrive2 for now.
qemu_sp3:
  pkgrepo.managed:
    - humanname: Qemu SP3
    - baseurl: http://download.suse.de/ibs/Devel:/Virt:/SLE-12-SP3/SUSE_SLE-12-SP2_Update_standard/
    - gpgcheck: False
    - refresh: True

qemu-arm:
  pkg.installed:
    - version: '>=2.8'
    - refresh: True
    - fromrepo: qemu_sp3
{% endif %}

kernel-default:
  pkg.installed:
    - refresh: True
    {% if 'Leap 42.1' in grains['oscodename'] %}
    - version: '>=4.4' # needed to fool zypper into the vendor change
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
      {% if grains['osarch'] == 'ppc64le' %}
      - qemu-ppc
      {% endif %}
      - atop
      - perl-XML-Writer # for virtualization tests
    - require:
      - pkg: worker-openqa.packages
{% if grains['osarch'] == 'aarch64' %}
      - pkg: qemu-arm
{% endif %}

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
#   available_webuis:
#     [webui_public_facing]:
#       testpoolurl: [rsync compatible path to grab tests webui_public_facing]
#     [webui_dev]:
#       testpoolurl: [rsync compatible path to grab tests from webui_dev]
#
#   [hostname of worker server]:
#     numofworkers: [number of workers]
#     client_key: [Client API Key]
#     client_secret: [Client API Secret]
#     webuis:
#       [webui_public_facing]:
#         key: [api key for this server]
#         secret: [api secret for this server]
#       […]
#     workers:
#       [number of worker instance]:
#         [workers.ini key]: [workers.ini value]
#         [workers.ini key]: [workers.ini value]
#       [number of worker instance]:
#         [workers.ini key]: [workers.ini value]
#
#   [hostname of worker server]:
#     numofworkers: [number of workers]
#     webuis:
#       [webui_public_facing]:
#         key: [api key for this server]
#         secret: [api secret for this server]
#       [webui_dev]
# etc ...
## example pillar
# workerconf:
#   available_webuis:
#     openqa.suse.de:
#       testpoolurl: rsnyc://openqa.suse.de/tests
#
#   openqaworker1:
#     numofworkers: 16
#     webuis:
#       [openqa.suse.de]
#         key: BLAHBLAHBLAH
#         secret: BLAHBLAHBLAH
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
        WORKER_HOSTNAME: {{ grains['fqdn_ip4'][0] }}
    - context:
      {% set workerhost = grains['host'] %}
      {% set workerdict = pillar.get('workerconf', {})[workerhost].get('workers', {}) %}
      {% set webuidict = pillar.get('workerconf', {})[workerhost].get('webuis', {}) %}
      workers: {{ workerdict }}
      webuis: {{ webuidict }}
    - require:
      - pkg: worker-openqa.packages

# setup client.conf based on info in workerconf pillar
/etc/openqa/client.conf:
  ini.options_present:
    - sections:
        {% set workerhost = grains['host'] %}
        {% set enabled_webuis = pillar.get('workerconf', {})[workerhost].get('webuis', {}) %}

        {% for webui in enabled_webuis %}
        {% set specific_key = pillar.get('workerconf', {})[workerhost].get('webuis', {}) %}
        {{ webui }}:
          key: {{ pillar['workerconf'][workerhost]['webuis'][webui]['key'] }}
          secret: {{ pillar['workerconf'][workerhost]['webuis'][webui]['secret'] }}
        {% endfor %}
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

{% if grains['osarch'] == 'aarch64' %}
/dev/raw1394:
  file.symlink:
    - target: /dev/null
/usr/share/qemu/qemu-uefi-aarch64.bin:
  file.managed:
    - source: salt://aarch64/qemu-uefi-aarch64.bin
{% endif %}

# os-autoinst starts local Xvnc with xterm and ssh - apparmor's chains are too strict for that
apparmor:
  pkg.purged

btrfs-nocow:
  cmd.run:
    - name: chattr +C /var/lib/openqa/cache && touch /var/lib/openqa/cache/.nocow
    - creates:
      - /var/lib/openqa/cache/.nocow
    - onlyif: which btrfs && btrfs filesystem df /var/lib/openqa/cache

python-augeas:
  pkg.installed

grub-conf:
  augeas.change:
    - require:
      - pkg: python-augeas
    - lens: Shellvars.lns
    - context: /files/etc/default/grub
    - changes:
      - set GRUB_TERMINAL '"serial console"'
      - set GRUB_CMDLINE_LINUX_DEFAULT '"console=tty0 console=ttyS1,115200"'
      - set GRUB_SERIAL_COMMAND '"serial --unit=1 --speed=115200"'

# TAPSCRIPT requires qemu to be able have the CAP_NET_ADMIN capability - Denis to investigate moving to openvswitch
{% set qemu_arch=grains['osarch'] %}
{% if qemu_arch == 'ppc64le' %}
{% set qemu_arch = 'ppc64' %}
{% endif %}
setcap cap_net_admin=ep /usr/bin/qemu-system-{{ qemu_arch }}:
  cmd.run:
    - unless: getcap /usr/bin/qemu-system-{{ qemu_arch }} | grep -q 'cap_net_admin+ep'
    - require:
      - pkg: worker.packages

# TAPSCRIPT requires _openqa-worker to be able to sudo
/etc/sudoers.d/_openqa-worker:
  file.managed:
    - mode: 600
    - contents:
      - '_openqa-worker ALL=(ALL) NOPASSWD: ALL'
