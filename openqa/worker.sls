{% if grains['osarch'] == 'x86_64' %}
{% set ttyconsolearg = "console=tty0 console=ttyS1,115200" %}
{% elif grains['osarch'] == 'aarch64' %}
{% set ttyconsolearg = "console=tty0 console=ttyAMA0,115200" %}
{% else %}
{% set ttyconsolearg = "" %}
{% endif %}

include:
 - openqa.repos
 - openqa.journal
 - openqa.ntp
 - sudo

# Packages that must come from the openQA repo
worker-openqa.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - openQA-worker
      - xterm-console
      - os-autoinst-openvswitch

# Packages that can come from anywhere
worker.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - kdump
      - x3270 # for s390x backend
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - xdotool # for ssh-x
      - ipmitool # for ipmi backend and generalhw
      - net-snmp # for generalhw backend
      - libcap-progs # for TAPSCRIPT
      - bridge-utils # for TAPSCRIPT and TAP support
      - firewalld # For TAP support and for other good reasons
      - qemu: '>=2.3'
      - telegraf # to collect metrics
      - iputils # ping for telegraf
      {% if grains['osarch'] == 'x86_64' %}
      - qemu-x86
      - qemu-ovmf-x86_64 # for UEFI
      {% endif %}
      {% if grains['osarch'] == 'ppc64le' %}
      - qemu-ppc
      - qemu-ipxe
      - qemu-vgabios
      {% endif %}
      {% if grains['osarch'] == 'aarch64' %}
      - qemu-arm
      - qemu-uefi-aarch64 # Replaces ovmf from linaro
      {% endif %}
      - os-autoinst-distri-opensuse-deps
      - ca-certificates-suse # secure connection with public-cloud-helper
    - require:
      - pkg: worker-openqa.packages

nfs-client:
  pkg.installed:
    - refresh: False

{%- if not grains.get('noservices', False) %}
# Ensure NFS share is mounted and setup on boot
/var/lib/openqa/share:
  mount.mounted:
    - device: {{ pillar['workerconf']['nfspath'] }}
    - fstype: nfs
    - opts: ro
    - require:
      - pkg: worker-openqa.packages
{%- endif %}

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
#       [...]
#     global:
#       [workers.ini key]: [workers.ini value]
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
    - context:
      {% set workerhost = grains['host'] %}
      {% set workerdict = pillar.get('workerconf', {}).get(workerhost, {}).get('workers', {}) %}
      {% set webuidict = pillar.get('workerconf', {}).get(workerhost, {}).get('webuis', {}) %}
      {% set globaldict = pillar.get('workerconf', {}).get(workerhost, {}).get('global', {}) %}
      {% do globaldict.update({'WORKER_HOSTNAME': grains['fqdn_ip4'][0]}) %}
      workers: {{ workerdict }}
      webuis: {{ webuidict }}
      global: {{ globaldict }}
    - require:
      - pkg: worker-openqa.packages

# setup client.conf based on info in workerconf pillar
/etc/openqa/client.conf:
  ini.options_present:
    - sections:
        {% set workerhost = grains['host'] %}
        {% set enabled_webuis = pillar.get('workerconf', {}).get(workerhost, {}).get('webuis', {}) %}

        {% for webui in enabled_webuis %}
        {% set specific_key = pillar.get('workerconf', {})[workerhost].get('webuis', {}) %}
        {{ webui }}:
          key: {{ pillar['workerconf'][workerhost]['webuis'][webui]['key'] }}
          secret: {{ pillar['workerconf'][workerhost]['webuis'][webui]['secret'] }}
        {% endfor %}
    - require:
      - pkg: worker-openqa.packages

{%- if not grains.get('noservices', False) %}
# start services based on numofworkers set in workerconf pillar
{% for i in range(pillar['workerconf'].get(grains['host'], {}).get('numofworkers', 0)) %}
{% set i = i+1 %}
openqa-worker@{{ i }}:
  service.running:
    - enable: True
{% if loop.first %}
    - require:
      - pkg: worker-openqa.packages
      - stop_and_disable_all_workers
{% endif %}
{% endfor %}

openqa-worker.target:
  service.running:
    - enable: True
    - require:
      - pkg: worker-openqa.packages

openqa-worker-cacheservice:
  service.running:
    - enable: True
    - require:
      - pkg: worker-openqa.packages

openqa-worker-cacheservice-minion:
  service.running:
    - enable: True
    - require:
      - pkg: worker-openqa.packages

# Stop and disable all openqa-worker@ service instances
stop_and_disable_all_workers:
  cmd.run:
    - name: systemctl disable --now openqa-worker@\*
    - onchanges:
      - file: /etc/openqa/workers.ini
{%- endif %}

# Configure firewalld: os-autoinst needs to upload logs to rather random ports and ovs needs configuration
{%- if not grains.get('noservices', False) %}
firewalld:
  service.running:
    - enable: True
    - watch_any:
      - file: /etc/firewalld/firewalld.conf
      - file: /etc/firewalld/zones/trusted.xml
    - require:
      - pkg: worker.packages
{%- endif %}
firewalld_config:
  file.replace:
    - name: /etc/firewalld/firewalld.conf
    - pattern: '^DefaultZone=.*$'
    - repl: 'DefaultZone=trusted'
    - append_if_not_found: True
    - require:
      - pkg: worker.packages
firewalld_zones:
  file.managed:
    - template: jinja
    - names:
      - /etc/firewalld/zones/trusted.xml:
        - source: salt://etc/firewalld/zones/trusted.xml
    - require:
      - pkg: worker.packages

{% if grains['osarch'] == 'aarch64' %}
/dev/raw1394:
  file.symlink:
    - target: /dev/null
{% endif %}

{% if grains['osarch'] == 'ppc64le' and 'ppc_powervm' in grains and not grains['ppc_powervm'] %}
{%- if not grains.get('noservices', False) %}
# As per bsc#1041747 we need a work around
# this service is provided by powerpc-utils
smt_off:
  service.running:
    - enable: True
{%- endif %}

/etc/modules-load.d/kvm.conf:
  file.managed:
    - contents:
      - 'kvm_hv'

/lib/udev/rules.d/80-kvm.rules:
  file.managed:
    - contents:
      - 'KERNEL=="kvm", MODE="0666", GROUP="kvm"'
{% endif %}

# os-autoinst starts local Xvnc with xterm and ssh - apparmor's chains are too strict for that
apparmor.removed:
  pkg.purged:
    - name: apparmor

{%- if not grains.get('noservices', False) %}
apparmor.disabled:
  service.dead:
    - name: apparmor
    - enable: False

apparmor.masked:
  service.masked:
    - name: apparmor
{%- endif %}

btrfs-nocow:
  cmd.run:
    - name: chattr +C /var/lib/openqa/cache && touch /var/lib/openqa/cache/.nocow
    - creates:
      - /var/lib/openqa/cache/.nocow
    - onlyif: which btrfs && btrfs filesystem df /var/lib/openqa/cache

python3-augeas:
  pkg.installed:
    # python3 is now a capability provided by a minor version package
    - resolve_capabilities: True
    - refresh: False

grub-conf:
  augeas.change:
    - require:
      - pkg: python3-augeas
    - lens: Shellvars.lns
    - context: /files/etc/default/grub
    - changes:
      - set GRUB_TERMINAL '"serial console"'
      - set GRUB_CMDLINE_LINUX_DEFAULT '"{{ ttyconsolearg }} nospec kvm.nested=1 kvm_intel.nested=1 kvm_amd.nested=1 kvm-arm.nested=1 crashkernel=210M"'
      - set GRUB_SERIAL_COMMAND '"serial --unit=1 --speed=115200"'

'grub2-mkconfig > /boot/grub2/grub.cfg':
  cmd.run:
    - onchanges:
      - augeas: grub-conf
    - onlyif: grub2-probe /boot

# TAPSCRIPT requires qemu to be able have the CAP_NET_ADMIN capability
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
    - require:
      - sudo

/etc/telegraf/telegraf.conf:
  file.managed:
    - name: /etc/telegraf/telegraf.conf
    - template: jinja
    - source:
      - salt://openqa/telegraf-worker.conf
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: worker.packages

/usr/lib/systemd/system/telegraf.service:
  file.managed:
    - name: /usr/lib/systemd/system/telegraf.service
    - source:
      - salt://openqa/telegraf.service
    - require:
      - pkg: worker.packages

{%- if not grains.get('noservices', False) %}
telegraf:
  service.running:
    - watch:
      - file: /etc/telegraf/telegraf.conf
{%- endif %}

/etc/systemd/system/os-autoinst-openvswitch.d/30-init-timeout.conf:
  file.managed:
    - name: /etc/systemd/system/os-autoinst-openvswitch.d/30-init-timeout.conf
    - mode: 644
    - source:
      - salt://openqa/os-autoinst-openvswitch-init-timeout.conf
    - makedirs: true

{%- if not grains.get('noservices', False) %}
openvswitch override reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/os-autoinst-openvswitch.d/30-init-timeout.conf
{% endif %}

# prevent I/O stuck for very long time by automatically crashing (and
# rebooting)
# see https://progress.opensuse.org/issues/41882#note-34
kernel.softlockup_panic:
  sysctl.present:
    - value: 1

{%- if grains.get('default_interface', None) %}
net.ipv6.conf.{{ grains['default_interface'] }}.accept_ra:
  sysctl.present:
    - value: 2
{%- endif %}

/etc/sysctl.d/50-vm-bytes.conf:
  file.managed:
    - source:
      - salt://etc/worker/50-vm-bytes.conf

'sysctl -p /etc/sysctl.d/50-vm-bytes.conf':
  cmd.run:
    - onchanges:
      - file: /etc/sysctl.d/50-vm-bytes.conf

kdump-conf:
  augeas.change:
    - require:
      - pkg: python3-augeas
    - lens: Shellvars.lns
    - context: /files/etc/sysconfig/kdump
    - changes:
      - set KDUMP_SMTP_SERVER '"relay.suse.de"'
      - set KDUMP_NOTIFICATION_TO '"osd-admins@suse.de"'

{%- if not grains.get('noservices', False) %}
# as kdump needs reserved memory which is only made effective by a reboot we
# must not start the service but only enable it to be started on bootup
kdump:
  service.enabled:
    - watch:
      - augeas: kdump-conf
{%- endif %}
