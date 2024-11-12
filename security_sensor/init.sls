{%- if not grains.get('noservices', False) %}
## Unconditionally enable and use the security sensor
## using an internal repo as requested on
## https://confluence.suse.com/display/CS/Sensor+-+Linux+Endpoint+Protection+Agent
## and
## https://gitlab.suse.de/linux-security-sensor/suse-client-deployment
## See https://progress.opensuse.org/issues/159060
{%    from 'openqa/repo_config.sls' import mirror, repo %}
security-sensor.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    - baseurl: http://{{ mirror }}/ibs/SUSE:/Velociraptor/{{ repo }}
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
