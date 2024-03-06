{%- if not grains.get('noservices', False) %}
## Unconditionally enable and use the security sensor for the development
## version to participate in the alpha-testing
## See https://progress.opensuse.org/issues/155179
{%    from 'openqa/repo_config.sls' import repo %}
security-sensor.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    - baseurl: https://download.opensuse.org/repositories/security:/sensor/{{ repo }}
    - gpgautoimport: True
    - refresh: True
    - priority: 90
    - require_in:
      - pkg: velociraptor-client

  pkg.latest:
    - name: velociraptor-client
    - refresh: False

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
