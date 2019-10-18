{% if 'Tumbleweed' in grains['oscodename'] %}
{% set openqarepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% set openqarepopath = "openSUSE_Leap_$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set openqarepopath = "SLE_12_SP3" %}
{% endif %}
{%- if grains.osrelease < '15.2' %}
telegraf-monitoring:
  pkgrepo.managed:
    - humanname: telegraf-monitoring
    - baseurl: https://download.opensuse.org/repositories/devel:/languages:/go/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 105

# workaround for https://progress.opensuse.org/issues/58331
# not using ini.options_present due to
# https://github.com/saltstack/salt/issues/33669
/etc/zypp/repos.d/telegraf-monitoring.repo:
  file.append:
    - text:
      - gpgautoimport=1
      - keeppackages=1

{%- endif %}

devel_openQA:
  pkgrepo.managed:
    - humanname: devel_openQA
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 95
    - keeppackages: True

/etc/zypp/repos.d/devel_openQA.repo:
  file.append:
    - text:
      - gpgautoimport=1
      - keeppackages=1

{% if openqamodulesrepo is defined %}
devel_openQA_Modules:
  pkgrepo.managed:
    - humanname: devel_openQA_Modules
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/{{ openqamodulesrepo }}/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 90
    - keeppackages: True

/etc/zypp/repos.d/devel_openQA_Modules.repo:
  file.append:
    - text:
      - gpgautoimport=1
      - keeppackages=1
{% endif %}
