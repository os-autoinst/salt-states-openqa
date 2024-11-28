{% from 'openqa/repo_config.sls' import repo %}
loki:
  pkg.latest:
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
