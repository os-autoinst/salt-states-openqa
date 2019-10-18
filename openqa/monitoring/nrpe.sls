{% if 'Tumbleweed' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Leap_$releasever" %}
{% elif 'SP2' in grains['oscodename'] %}
{% set opensuserepopath = "SUSE_SLE_12_SP2_Update" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set opensuserepopath = "SUSE_SLE_12_SP3_Update" %}
{% endif %}

NPI:
  pkgrepo.managed:
    - humanname: Infra
    - baseurl: http://download.suse.de/ibs/NON_Public:/infrastructure/{{ opensuserepopath }}/
    - gpgcheck: False
    - refresh: True

{%- if not grains.get('noservices', False) %}
xinetd:
  service.running:
    - enable: True
    - require:
      - pkg: worker-monitoring.packages

nrpe:
  service.running:
    - enable: True
    - require:
      - pkg: worker-monitoring.packages
{%- endif %}

/etc/nagios/check_zypper-ignores.txt:
  file.managed:
    - source: salt://openqa/monitoring/infra/check_zypper-ignores.txt
    - require:
      - pkg: worker-monitoring.packages

/etc/nrpe.cfg:
  file.managed:
    - source:
      - salt://openqa/monitoring/infra/nrpe.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: worker-monitoring.packages

/etc/nrpe.d:
  file.recurse:
    - name: /etc/nrpe.d
    - source: salt://openqa/monitoring/infra/nrpe.d
    - user: root
    - group: root
    - makedirs: True
    - file_mode: 744
    - dir_mode: 755
    - require:
      - pkg: worker-monitoring.packages

/etc/nagios:
  file.directory:
    - name: /etc/nagios
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - require:
      - pkg: worker-monitoring.packages

/etc/xinetd.d/check_mk:
  file.managed:
    - source:
      - salt://openqa/monitoring/infra/check_mk
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: worker-monitoring.packages

worker-monitoring.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - xinetd
      - nrpe
      - check_mk-agent
      - monitoring-plugins-zypper
      - monitoring-plugins-users
      - monitoring-plugins-swap
      - monitoring-plugins-sar-perf
      - monitoring-plugins-procs
      - monitoring-plugins-ntp_time
      - monitoring-plugins-multipath
      - monitoring-plugins-mem
      - monitoring-plugins-load
      - monitoring-plugins-disk
      - monitoring-plugins-common
    - fromrepo: NPI

