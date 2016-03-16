openQA:
  pkgrepo.managed:
    - humanname: openQA (Leap 42.1)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/openSUSE_Leap_42.1/
    - gpgcheck: 0
    - autorefresh: 1

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

worker-openqa.packages: # Packages that must come from the openQA repo
  pkg.installed:
    - refresh: 1
    - pkgs:
      - openQA-worker
      - xterm-console
      - freeipmi
    - fromrepo: openQA

worker.packages: # Packages that can come from anywhere
  pkg.installed:
    - refresh: 1
    - pkgs:
      - x3270 # for s390x backend
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - qemu-ovmf-x86_64 # for UEFI
      - ipmitool # for ipmi backend and generalhw
      - net-snmp # for generalhw backend
      - qemu: '>=2.3'

/var/lib/openqa/share:
  mount.mounted:
    - device: '{{ pillar['workerconf']['openqahost'] }}:/var/lib/openqa/share'
    - fstype: nfs
    - opts: ro
    - require:
      - pkg: worker-openqa.packages

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

/etc/openqa/client.conf:
  ini.sections_present:
    - sections:
        {{ pillar['workerconf']['openqahost'] }}:
          key: {{ pillar['workerconf'][grains['host']]['client_key'] }}
          secret: {{ pillar['workerconf'][grains['host']]['client_secret'] }}
    - require:
      - pkg: worker-openqa.packages

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

