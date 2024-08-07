{% from 'openqa/repo_config.sls' import repo %}
{% if 'Leap' in grains['oscodename'] %}
{% set openqamodulesrepo = "Leap:/$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set openqamodulesrepo = "SLE-12" %}
{% endif %}

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
  file.replace:
    - pattern: '^keeppackages=0$'
    - repl: 'keeppackages=1'
    - append_if_not_found: True
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
  file.replace:
    - pattern: '^keeppackages=0$'
    - repl: 'keeppackages=1'
    - append_if_not_found: True
    - require:
      - pkgrepo: devel_openQA_Modules
{% endif %}

## Special OVMF assets needed for secureboot testing of SLFO and SLE 15SP7
## https://progress.opensuse.org/issues/164150
{%- if grains.get('roles', '') in ['worker'] and grains['osarch'] == 'x86_64' %}
home_favogt_stagingovmf_repo:
  pkgrepo.managed:
    - humanname: home_favogt_stagingovmf
    - baseurl: https://download.suse.de/ibs/home:/favogt:/stagingovmf/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 85
    - keeppackages: True
    - retry:
        attempts: 5
{% endif %}
