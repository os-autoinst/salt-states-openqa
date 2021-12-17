{% from 'openqa/repo_config.sls' import repo %}
{% if 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% endif %}

{%- if grains.osrelease < '15.2' %}
telegraf-monitoring:
  pkgrepo.managed:
    - humanname: telegraf-monitoring
    - baseurl: http://download.opensuse.org/repositories/devel:/languages:/go/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 105
    - retry: True

# workaround for https://progress.opensuse.org/issues/58331
# not using ini.options_present due to
# https://github.com/saltstack/salt/issues/33669
/etc/zypp/repos.d/telegraf-monitoring.repo:
  file.append:
    - text:
      - keeppackages=1
    - require:
      - pkgrepo: telegraf-monitoring

{%- endif %}

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
    - retry: True

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
    - retry: True

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
