{%- if not grains.get('noservices', False) %}
{% from 'openqa/repo_config.sls' import repo %}
security-sensor.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    # the url should just be "…/sensor/{{ repo }}" but seems like the repo does not follow our repo name standards yet
    - baseurl: https://download.opensuse.org/repositories/security:/sensor/openSUSE_Leap_{{ repo }}
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
