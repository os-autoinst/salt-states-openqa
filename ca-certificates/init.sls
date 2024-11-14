{% from 'openqa/repo_config.sls' import repo %}
SUSE_CA:
  pkgrepo.managed:
    - humanname: SUSE_CA
    - baseurl: https://download.opensuse.org/repositories/SUSE:/CA/{{ repo }}/
    - gpgautoimport: True
    - refresh: True
    - priority: 110

ca-certificates-suse:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5

/etc/systemd/system/ca-certificates.service.d/override.conf:
  file.managed:
    - source: salt://ca-certificates/override.conf
    - makedirs: True
