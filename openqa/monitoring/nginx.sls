nginx:
  pkg.latest:
    - refresh: False

/etc/nginx/vhosts.d/02-grafana.conf:
  file.managed:
    - source: salt://openqa/monitoring/grafana/02-grafana.conf

{%- if not grains.get('noservices', False) %}
nginx:
  service.running:
    - watch:
      - file: /etc/nginx/vhosts.d/02-grafana.conf
{%- endif %}
