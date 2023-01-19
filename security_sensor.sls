{%- if not grains.get('noservices', False) %}
{% from 'openqa/repo_config.sls' import repo %}
security-sensor.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    - baseurl: https://download.opensuse.org/repositories/security:/sensor/{{ repo }}
    - gpgautoimport: True
    - refresh: True
    - priority: 105
    - require_in:
      - pkg: velociraptor-client

  pkg.latest:
    - name: velociraptor-client
    - refresh: False

/etc/velociraptor/client.config:
  file.managed:
    - mode: 644
    - contents_pillar: velociraptor-client.config

velociraptor-client.service:
  service.enabled:
    - watch:
      - file: /etc/velociraptor/client.config
{%- endif %}
