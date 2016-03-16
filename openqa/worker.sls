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
      - xorg-x11-Xvnc
      - qemu-ovmf-x86_64
      - qemu: '>=2.3'

/var/lib/openqa/share:
  mount.mounted:
    - device: '{{ pillar['workerconf']['openqahost'] }}:/var/lib/openqa/share'
    - fstype: nfs
    - opts: ro
    - require:
      - pkg: worker-openqa.packages

/etc/openqa/workers.ini:
  ini.sections_present:
    - sections:
        global:
          HOST: http://{{ pillar['workerconf']['openqahost'] }}
          WORKER_HOSTNAME: {{ grains['fqdn_ip4'] }}
        {% set workerhost = grains['host'] %}
        {% set workerdict = pillar.get('workerconf', {})[workerhost]['workers'] %}
        {% for workerid, details in workerdict.items() %}
        {{ workerid }}:
          {{ details }}
        {% endfor %}
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
{% endfor %}

