databases.repo:
{% if 'Leap' in grains['oscodename'] %}
{% set repo = "$releasever" %}
  pkgrepo.managed:
    - humanname: Databases
    - baseurl: http://download.opensuse.org/repositories/server:/database/{{ repo }}
    - enabled: True
    - gpgautoimport: True
    - priority: 105
    - require_in:
      - pkg: influxdb
{% endif %}

  pkg.latest:
    - name: influxdb
    - refresh: False
