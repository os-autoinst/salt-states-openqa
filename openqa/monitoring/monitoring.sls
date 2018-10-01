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
    - onchanges:
      - file: /etc/collectd.conf
  file.managed:
    - name: /etc/collectd.conf
    - source:
      - salt://openqa/monitoring/collectd.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: webui-monitoring.packages

webui-monitoring.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - collectd
