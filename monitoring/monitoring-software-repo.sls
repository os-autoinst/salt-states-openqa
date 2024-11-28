{% from 'openqa/repo_config.sls' import repo %}
monitoring-software.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/monitoring/{{ repo }}
    - gpgautoimport: True
    - refresh: True
    - priority: 90
    - require_in:
      - pkg: grafana
      - pkg: loki
