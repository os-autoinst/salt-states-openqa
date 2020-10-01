nginx:
  pkg.latest:
    - refresh: False
{%- if not grains.get('noservices', False) %}
  service.running:
    - watch:
      - file: /etc/nginx/vhosts.d/02-grafana.conf
{%- endif %}

/etc/nginx/vhosts.d/02-grafana.conf:
  file.managed:
    - source: salt://openqa/monitoring/grafana/02-grafana.conf
