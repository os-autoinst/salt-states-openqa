{% from 'openqa/repo_config.sls' import repo %}
{% if 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% endif %}

SUSE_CA:
  pkgrepo.managed:
    - humanname: SUSE_CA
    - baseurl: http://download.suse.de/ibs/SUSE:/CA/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 110

devel_openQA:
  pkgrepo.managed:
    - humanname: devel_openQA
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 95
    - keeppackages: True
    - retry:
        attempts: 5

/etc/zypp/repos.d/devel_openQA.repo:
  file.append:
    - text:
      - keeppackages=1
    - require:
      - pkgrepo: devel_openQA

{% if openqamodulesrepo is defined %}
devel_openQA_Modules:
  pkgrepo.managed:
    - humanname: devel_openQA_Modules
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/{{ openqamodulesrepo }}/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 90
    - keeppackages: True
    - retry:
        attempts: 5

/etc/zypp/repos.d/devel_openQA_Modules.repo:
  file.append:
    - text:
      - keeppackages=1
    - require:
      - pkgrepo: devel_openQA_Modules
{% endif %}

# We keep proper priorities on our repositories so we can rely on sensible,
# automatic choices for vendor changes
/etc/zypp/zypp.conf:
  ini.options_present:
    - sections:
        main:
          solver.dupAllowVendorChange: true
