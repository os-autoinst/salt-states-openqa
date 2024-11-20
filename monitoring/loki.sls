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

  pkg.latest:
    - name: loki
    - refresh: False

/etc/loki/loki.yaml:
  file.managed:
    - source: salt://monitoring/loki/loki.yaml
    - mode: "0644"

{%- if not grains.get('noservices', False) %}
loki:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/loki/loki.yaml
{%- endif %}
