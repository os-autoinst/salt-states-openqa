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

/usr/local/bin/influxdb-remove-old-data.sh:
  file.managed:
    - source: salt://monitoring/influxdb-remove-old-data.sh
    - user: root
    - group: root
    - mode: "0755"

/etc/systemd/system/influxdb-remove-old-data.service:
  file.managed:
    - contents: |
         [Unit]
         Description=Remove old and big data in influxdb
         [Service]
         Type=oneshot
         ExecStart=/usr/local/bin/influxdb-remove-old-data.sh

/etc/systemd/system/influxdb-remove-old-data.timer:
  file.managed:
    - contents: |
        [Unit]
        Description=Remove old and big data in influxdb periodically
        [Timer]
        OnCalendar=01:28
        Persistent=True
        Unit=influxdb-remove-old-data.service
        [Install]
        WantedBy=timers.target

{% if not grains.get('noservices', False) %}
  service.running:
    - name: influxdb-remove-old-data.timer
    - enable: true
{% endif %}
