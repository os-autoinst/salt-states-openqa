databases.repo:
  pkgrepo.managed:
    - humanname: Databases
    - baseurl: https://download.opensuse.org/repositories/server:/database/openSUSE_Leap_$releasever/
    - enabled: True
    - gpgautoimport: True
    - require_in:
      - pkg: influxdb

  pkg.latest:
    - name: influxdb
    - refresh: True
