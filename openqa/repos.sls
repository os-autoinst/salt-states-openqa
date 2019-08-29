# compatibility handling of old instances
/etc/zypp/repos.d/devel_openQA_Leap.repo:
  file.absent

{% if 'Tumbleweed' in grains['oscodename'] %}
{% set openqarepopath = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% set openqarepopath = "openSUSE_Leap_$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% set openqarepopath = "SLE_12_SP3" %}
{% endif %}
{% if grains['osarch'] == 'x86_64' %}
{% set ttyconsolearg = "console=tty0 console=ttyS1,115200" %}
{% else %}
{% set ttyconsolearg = "" %}
{% endif %}
devel_openQA:
  pkgrepo.managed:
    - humanname: devel_openQA
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True

telegraf-monitoring:
  pkgrepo.managed:
    - humanname: telegraf-monitoring
    - baseurl: https://download.opensuse.org/repositories/devel:/languages:/go/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True

{% if openqamodulesrepo %}
devel_openQA_Modules:
  pkgrepo.managed:
    - humanname: devel_openQA_Modules
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/{{ openqamodulesrepo }}/{{ openqarepopath }}/
    - gpgautoimport: True
    - refresh: True
{% endif %}
