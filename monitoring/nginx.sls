nginx:
  pkg.latest:
    - refresh: False
{%- if not grains.get('noservices', False) %}
  service.running:
    - enable: True
    - watch:
      - file: /etc/nginx/vhosts.d/02-grafana.conf
      - file: /etc/nginx/vhosts.d/03-loki.conf
      - file: /etc/nginx/auth/loki
{%- endif %}

/etc/nginx/vhosts.d/02-grafana.conf:
  file.managed:
    - source: salt://monitoring/grafana/02-grafana.conf

/etc/nginx/vhosts.d/03-loki.conf:
  file.managed:
    - source: salt://monitoring/loki/03-loki.conf

/etc/nginx/auth/loki:
  file.managed:
{%- if pillar.get("http_basic_auth_users", False) %}
    - contents_pillar: http_basic_auth_users
{%- endif %}
    - allow_empty: True
    - user: root
    - group: root
    - mode: "0664"
    - makedirs: True

webserver_grain:
  grains.present:
    - name: webserver
    - value: nginx
