{% if grains['osarch'] == 'x86_64' %}
{% set serial_tty_default = "ttyS1,115200" %}
{% elif grains['osarch'] == 'aarch64' %}
{% set serial_tty_default = "ttyAMA0,115200" %}
{% else %}
{% set serial_tty_default = None %}
{% endif %}
{% set serial_tty = pillar['workerconf'].get(grains['host'], {}).get('tty_dev', serial_tty_default) %}
{% if serial_tty %}
{% set ttyconsolearg = "console=tty0 console=" + serial_tty %}
{% else %}
{% set ttyconsolearg = "" %}
{% endif %}

include:
 - openqa.repos
 - openqa.journal
{%- if grains.get('openqa_share_nfs', False) or grains.get('roles', '') in ['worker'] %}
 - openqa.nfs_share
{%- endif %}
 - sudo

worker.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - openQA-worker
      - xterm-console
      - samba  # required by jobs using the setting QEMU_ENABLE_SMBD=1
      - os-autoinst-openvswitch
      - x3270 # for s390x backend
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - xdotool # for ssh-x
      - e2fsprogs # for chattr
      - ipmitool # for ipmi backend and generalhw
      - net-snmp # for generalhw backend
      - libcap-progs # for TAPSCRIPT
      - bridge-utils # for TAPSCRIPT and TAP support
      - firewalld # For TAP support and for other good reasons
      - ffmpeg-4 # For VP9/AV-1 support in os-autoinst
      - qemu: '>=2.3'
      {% if grains['osarch'] == 'x86_64' %}
      - qemu-x86
      - qemu-ovmf-x86_64 # for UEFI
      {% endif %}
      - os-autoinst-swtpm
      ## allow to emulate ppc on x86_64 as well
      ## https://progress.opensuse.org/issues/163451
      {% if grains['osarch'] == 'ppc64le' or grains['osarch'] == 'x86_64' %}
      - qemu-ppc
      - qemu-ipxe
      - qemu-vgabios
      {% endif %}
      {% if grains['osarch'] == 'aarch64' %}
      - qemu-arm
      - qemu-uefi-aarch64 # Replaces ovmf from linaro
      {% endif %}
      {% if grains['osarch'] == 'aarch64' or grains['osarch'] == 'x86_64' %}
      - vagrant
      - vagrant-libvirt
      {% endif %}
      - os-autoinst-distri-opensuse-deps

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
    - source: salt://openqa/workers.ini
    - template: jinja
    - user: root
    - group: root
    - mode: "0644"
    - context:
      {% set workerhost = grains['host'] %}
      {% set workerdict = pillar.get('workerconf', {}).get(workerhost, {}).get('workers', {}) or {} %}
      {% set webuidict = pillar.get('workerconf', {}).get(workerhost, {}).get('webuis', {}) %}
      {% set globaldict = pillar.get('workerconf', {}).get('global', {}) %}
      {% set global = pillar.get('workerconf', {}).get(workerhost, {}).get('global', {}) %}
      {% do globaldict.update(global) %}
      workers: {{ workerdict }}
      webuis: {{ webuidict }}
      global: {{ globaldict }}
    - require:
      - pkg: worker.packages

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
      - pkg: worker.packages

/etc/systemd/system/openqa-worker-auto-restart@.service.d/30-openqa-max-inactive-caching-downloads.conf:
  file.managed:
    - mode: "0644"
    - source: salt://openqa/openqa-max-inactive-caching-downloads.conf
    - makedirs: true
    - require:
      - pkg: worker.packages

{%- if not grains.get('noservices', False) %}
# start services based on numofworkers set in workerconf pillar
{% set worker_slot_count = pillar['workerconf'].get(grains['host'], {}).get('numofworkers', 0) %}
{% for i in range(worker_slot_count) %}
{% set i = i+1 %}
openqa-worker-auto-restart@{{ i }}:
  service.running:
    - enable: True
    - unless:
      - fun: service.masked
        args:
          - openqa-worker-auto-restart@{{ i }}
    - watch:
      - file: /etc/systemd/system/openqa-worker-auto-restart@.service.d/30-openqa-max-inactive-caching-downloads.conf
{% if loop.first %}
    - require:
      - pkg: worker.packages
      - stop_and_disable_all_not_configured_workers
{% endif %}

openqa-reload-worker-auto-restart@{{ i }}.path:
  service.running:
    - enable: True
    - unless:
      - fun: service.masked
        args:
          - openqa-worker-auto-restart@{{ i }}
    - unless:
      - fun: service.masked
        args:
          - openqa-reload-worker-auto-restart@{{ i }}
{% endfor %}

# switch from openqa-worker-plain@ to openqa-worker-auto-restart@
/etc/systemd/system/openqa-worker@.service:
  file.symlink:
    - target: /usr/lib/systemd/system/openqa-worker-auto-restart@.service

openqa-worker.target:
  service.disabled

openqa-worker-cacheservice:
  service.running:
    - enable: True
    - require:
      - pkg: worker.packages

openqa-worker-cacheservice-minion:
  service.running:
    - enable: True
    - require:
      - pkg: worker.packages

# Stop and disable all openqa-worker-auto-restart@ service instances which are exceeding the configured
# number of worker slots
stop_and_disable_all_not_configured_workers:
  cmd.run:
    - name: services=$(systemctl list-units --all 'openqa-worker-auto-restart@*.service' | sed -e '/.*openqa-worker-auto-restart@.*\.service.*/!d' -e 's|.*openqa-worker-auto-restart@\(.*\)\.service.*|\1|' | awk '{ if($0 > {{ worker_slot_count }}) print "openqa-worker-auto-restart@" $0 ".service openqa-reload-worker-auto-restart@" $0 ".path" }' | tr '\n' ' '); [ -z "$services" ] || systemctl disable --now $services
    - unless: test $(systemctl list-units --legend=false --all 'openqa-worker-auto-restart@*.service' | wc -l) -eq {{ worker_slot_count }}
{%- endif %}

# Configure firewalld: os-autoinst needs to upload logs to rather random ports and ovs needs configuration
{%- if not grains.get('noservices', False) %}
firewalld:
  service.running:
    - enable: True
    - watch_any:
      - file: /etc/firewalld/firewalld.conf
{% if grains.get('host') in pillar.get('workerconf').keys() %}
      - file: /etc/firewalld/zones/trusted.xml
{% endif %}
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
{% if grains.get('host') in pillar.get('workerconf').keys() %}
firewalld_zones:
  file.managed:
    - template: jinja
    - names:
      - /etc/firewalld/zones/trusted.xml:
        - source: salt://etc/firewalld/zones/trusted.xml
    - require:
      - pkg: worker.packages

# ensures the bridge_iface is only present in our own zone if
# e.g. the installer put it into a different one
move_interface:
  cmd.run:
    - unless: test $(firewall-cmd --get-zone-of-interface={{ pillar['workerconf'][grains['host']]['bridge_iface'] }}) == "trusted"
    - name: sed -i '/name="{{ pillar['workerconf'][grains['host']]['bridge_iface'] }}"/d' /etc/firewalld/zones/*.xml; firewall-cmd --reload; firewall-cmd --zone=trusted --change-interface={{ pillar['workerconf'][grains['host']]['bridge_iface'] }} --permanent
{% endif %}

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

{%- if grains.osrelease < '15.3' %}
/lib/udev/rules.d/80-kvm.rules:
{%- else %}
/usr/lib/udev/rules.d/80-kvm.rules:
{%- endif %}
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

{% set additional_linux_cmdline_args = pillar['workerconf'].get(grains['host'], {}).get('additional_linux_cmdline_args', '') %}
grub-conf-terminal:
  file.replace:  # not using augeas here and below as it cannot handle the "+="-syntax used in kdump.sls
    - name: /etc/default/grub
    - pattern: '^GRUB_TERMINAL=.*$'
    - repl: 'GRUB_TERMINAL="serial console"'
    - append_if_not_found: True

grub-conf-cmdline:
  file.replace:
    - name: /etc/default/grub
    - pattern: '^GRUB_CMDLINE_LINUX_DEFAULT=.*$'
    - repl: 'GRUB_CMDLINE_LINUX_DEFAULT="{{ ttyconsolearg }} nospec kvm.nested=1 kvm_intel.nested=1 kvm_amd.nested=1 kvm-arm.nested=1 {{ additional_linux_cmdline_args }}"'
    - append_if_not_found: True

grub-conf-serial-cmd:
  file.replace:
    - name: /etc/default/grub
    - pattern: '^GRUB_SERIAL_COMMAND=.*$'
    - repl: 'GRUB_SERIAL_COMMAND="serial --unit=1 --speed=115200"'
    - append_if_not_found: True

'grub2-mkconfig -o /boot/grub2/grub.cfg':
  cmd.run:
    - onchanges:
      - file: grub-conf-terminal
      - file: grub-conf-cmdline
      - file: grub-conf-serial-cmd
    - onlyif: grub2-probe /boot

# TAPSCRIPT requires qemu to be able have the CAP_NET_ADMIN capability
{% set qemu_arch=grains['osarch'] %}
{% if qemu_arch == 'ppc64le' %}
{% set qemu_arch = 'ppc64' %}
{% endif %}
setcap cap_net_admin=ep /usr/bin/qemu-system-{{ qemu_arch }}:
  cmd.run:
    - unless: getcap /usr/bin/qemu-system-{{ qemu_arch }} | grep -q 'cap_net_admin=ep'
    - require:
      - pkg: worker.packages


# TAPSCRIPT requires _openqa-worker to be able to sudo
/etc/sudoers.d/_openqa-worker:
  file.managed:
    - mode: "0600"
    - contents:
      - '_openqa-worker ALL=(ALL) NOPASSWD: ALL'
    - require:
      - sudo

/etc/telegraf/telegraf.d/telegraf-worker.conf:
  file.managed:
    - template: jinja
    - source: salt://monitoring/telegraf/telegraf-worker.conf
    - user: root
    - group: root
    - mode: "0600"
    - makedirs: True
    - require:
      - pkg: worker.packages

{%- if not grains.get('noservices', False) %}
# prevent I/O stuck for very long time by automatically crashing (and
# rebooting)
# see https://progress.opensuse.org/issues/41882#note-34
kernel.softlockup_panic:
  sysctl.present:
    - value: 1
{%- endif %}

{%- if grains.get('default_interface', None) %}
net.ipv6.conf.{{ grains['default_interface'] }}.accept_ra:
  sysctl.present:
    - value: 2
{%- endif %}

/etc/sysctl.d/50-vm-bytes.conf:
  file.managed:
    - source: salt://etc/worker/50-vm-bytes.conf

'sysctl -p /etc/sysctl.d/50-vm-bytes.conf':
  cmd.run:
    - onchanges:
      - file: /etc/sysctl.d/50-vm-bytes.conf
