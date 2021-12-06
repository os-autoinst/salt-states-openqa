nginx:
  pkg.latest:
    - refresh: False
{%- if not grains.get('noservices', False) %}
  service.running:
    - enable: True
    - watch:
      - file: /etc/nginx/vhosts.d/02-grafana.conf
{%- endif %}

webserver_config:
  file.managed:
    - name: /etc/nginx/vhosts.d/02-grafana.conf
    - source: salt://monitoring/grafana/02-grafana.conf

webserver_grain:
  grains.present:
    - name: webserver
    - value: nginx
