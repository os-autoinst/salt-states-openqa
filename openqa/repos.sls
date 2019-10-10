{% if 'Tumbleweed' in grains['oscodename'] %}
{% set openqarepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% set openqarepopath = "openSUSE_Leap_$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set openqarepopath = "SLE_12_SP3" %}
{% endif %}
telegraf-monitoring:
  pkgrepo.managed:
    - humanname: telegraf-monitoring
    - baseurl: https://download.opensuse.org/repositories/devel:/languages:/go/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 105

devel_openQA:
  pkgrepo.managed:
    - humanname: devel_openQA
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 95

{% if openqamodulesrepo is defined %}
devel_openQA_Modules:
  pkgrepo.managed:
    - humanname: devel_openQA_Modules
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/{{ openqamodulesrepo }}/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 90
{% endif %}
