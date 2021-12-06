nginx:
  pkg.latest:
    - refresh: False
{%- if not grains.get('noservices', False) %}
  service.running:
    - enable: True
    - watch:
      - file: /etc/nginx/vhosts.d/02-grafana.conf
{%- endif %}

/etc/nginx/vhosts.d/02-grafana.conf:
  file.managed:
    - source: salt://monitoring/grafana/02-grafana.conf

webserver_grain:
  grains.present:
    - name: webserver
    - value: nginx
