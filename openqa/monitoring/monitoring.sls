{% if 'Tumbleweed' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set opensuserepopath = "openSUSE_Leap_" + grains['osrelease'] %}
{% elif 'SP2' in grains['oscodename'] %}
{% set opensuserepopath = "SUSE_SLE_12_SP2_Update" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set opensuserepopath = "SUSE_SLE_12_SP3_Update" %}
{% else %}
{% set opensuserepopath = "openSUSE_" + grains['osrelease'] %}
{% endif %}

collectd:
  service.running:
    - enable: True
    - require:
      - pkg: webui-monitoring.packages

#/etc/nrpe.cfg:
#  file.managed:
#    - source:
#      - salt://openqa/monitoring/infra/nrpe.cfg
#    - template: jinja
#    - user: root
#    - group: root
#    - mode: 644
#    - require:
#      - pkg: worker-monitoring.packages

/etc/collectd.conf:
  file.managed:
    - source:
      - salt://openqa/monitoring/collectd.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: webui-monitoring.packages

#/etc/xinetd.d/check_mk:
#  file.managed:
#    - source:
#      - salt://openqa/monitoring/infra/check_mk
#    - template: jinja
#    - user: root
#    - group: root
#    - mode: 644
#    - require:
#      - pkg: worker-monitoring.packages

webui-monitoring.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - collectd
#  - xinetd
#  - nrpe
#  - check_mk-agent
#  - monitoring-plugins-zypper
#  - monitoring-plugins-users
#  - monitoring-plugins-swap
#  - monitoring-plugins-sar-perf
#  - monitoring-plugins-procs
#  - monitoring-plugins-ntp_time
#  - monitoring-plugins-multipath
#  - monitoring-plugins-mem
#  - monitoring-plugins-load
#  - monitoring-plugins-disk
#  - monitoring-plugins-common
