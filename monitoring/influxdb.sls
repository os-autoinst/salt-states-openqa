{% from 'openqa/repo_config.sls' import repo %}
databases.repo:
  pkgrepo.managed:
    - humanname: Databases
    - baseurl: http://download.opensuse.org/repositories/server:/database/{{ repo }}
    - enabled: True
    - gpgautoimport: True
    - priority: 105
    - require_in:
      - pkg: influxdb

  pkg.latest:
    - name: influxdb
    - refresh: False
