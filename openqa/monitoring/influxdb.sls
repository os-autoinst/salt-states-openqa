{% from 'openqa/repo_config.sls' import repo %}
databases.repo:
  pkgrepo.managed:
    - humanname: Databases
    - baseurl: https://download.opensuse.org/repositories/server:/database/{{ repo }}
    - enabled: True
    - gpgautoimport: True
    - require_in:
      - pkg: influxdb

  pkg.latest:
    - name: influxdb
    - refresh: True
