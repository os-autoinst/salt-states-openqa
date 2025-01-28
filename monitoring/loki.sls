{% from 'openqa/repo_config.sls' import repo %}
loki:
  pkg.latest:
    - refresh: False
    - retry:
        attempts: 5
{%- if not grains.get('noservices', False) %}
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/loki/loki.yaml
{%- endif %}

/etc/loki/loki.yaml:
  file.managed:
    - source: salt://monitoring/loki/loki.yaml
    - mode: "0644"
