{%- if not grains.get('noservices', False) %}
security-sensor:
  pkg.latest:
    - name: velociraptor-client
    - refresh: False
    - retry:
        attempts: 5

/etc/sysconfig/velociraptor-client:
  file.replace:
    - pattern: '^VELOCIRAPTOR_CLIENT_OPTS="([^"]*\s)?-v(\s[^"]*)?"$'
    - repl: 'VELOCIRAPTOR_CLIENT_OPTS="\1\2"'

/etc/velociraptor/client.config:
  file.managed:
    - mode: "0644"
    - contents_pillar: velociraptor-client.config

/etc/systemd/system/velociraptor-client.service.d/override.conf:
  file.managed:
    - source: salt://security_sensor/override.conf
    - makedirs: True

velociraptor-client.service:
  service.enabled:
    - watch:
      - file: /etc/velociraptor/client.config
      - file: /etc/systemd/system/velociraptor-client.service.d/override.conf
{%- endif %}
