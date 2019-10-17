{% if 'Tumbleweed' in grains['oscodename'] %}
  {% if 'aarch64' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Factory_ARM_images" %}
  {% elif 'ppc64le' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Factory_PowerPC" %}
  {% elif 's390x' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Factory_zSystems_standard" %}
  {% elif 'x86_64' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Tumbleweed" %}
  {% endif %}
{% elif 'Leap 15.1' in grains['oscodename'] %}
  {% if 'aarch64' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Leap_15.1_ARM" %}
  {% elif 'x86_64' in grains['cpuarch'] %}
    {% set qsfrepopath = "openSUSE_Leap_15.1" %}
  {% endif %}
{% elif '12 SP4' in grains['oscodename'] %}
  {% set qsfrepopath = "SLE_12_SP4_Backports" %}
{% elif '15 SP1' in grains['oscodename'] %}
  {% set qsfrepopath = "SLE_15_SP1_Backports" %}
{% endif %}

{% if qsfrepopath is defined %}
kvm.repo:
  pkgrepo.managed:
    - humanname: QSF
    - name: QSF
    - baseurl: https://download.opensuse.org/repositories/devel:/openSUSE:/QA:/QSF/{{ qsfrepopath }}
    - gpgautoimport: True
    - refresh: True

kvm.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - auto-restart-libvirtd
    - fromrepo: QSF
    - require:
      - pkgrepo: kvm.repo

{%- if not grains.get('noservices', False) %}
kvm.auto-restart-libvirtd-timer-started:
  service.running:
    - name: restart-libvirtd.timer
    - enable: True
    - require:
      - pkg: kvm.packages
{%- endif %}
{% endif %}
