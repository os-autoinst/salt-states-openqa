{% if 'Tumbleweed' in grains['oscodename'] %}
{% set repo = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set repo = "$releasever" %}
{% endif %}

databases.repo:
  pkgrepo.managed:
    - humanname: Databases
    - baseurl: http://download.opensuse.org/repositories/server:/database/{{ repo }}
    - enabled: True
    - gpgautoimport: True
    - priority: 105
    - require_in:
      - pkg: influxdb

  pkg.latest:
    - name: influxdb
    - refresh: False
