server-monitoring-software.repo:
  pkgrepo.managed:
    - humanname: Server Monitoring Software
    - baseurl: https://download.opensuse.org/repositories/server:/monitoring/openSUSE_Leap_15.1/
    - enabled: True
    - gpgautoimport: True
    - require_in:
      - pkg: grafana

  pkg.latest:
    - name: grafana
    - refresh: True

/var/run/grafana:
  file.directory:
    - user: grafana
    - group: grafana
    - mode: 770

reverse-proxy-group:
  group.present:
  - addusers:
    - nginx

/etc/grafana/grafana.ini:
  ini.options_present:
    - separator: '='
    - strict: True
    - sections:
        server:
          protocol: socket
          domain: 'stats.openqa-monitor.qa.suse.de'
          root_url: 'http://stats.openqa-monitor.qa.suse.de'
          socket: '/var/run/grafana/grafana.socket'
        analytics:
          reporting_enabled: false
          check_for_updates: false
        snapshots:
          external_enabled: false
        dashboards:
          versions_to_keep: 40
        users:
          allow_sign_up: false
          allow_org_create: false
        auth.anonymous:
          enabled: true
          org_name: 'SUSE'
          org_role: 'Viewer'

/etc/grafana/provisioning/dashboards/salt.yaml:
  file.managed:
    source: salt://openqa/monitoring/grafana/salt.yaml

/var/lib/grafana/dashboards/webui.dashboard.json:
  file.managed:
    source: salt://openqa/monitoring/grafana/webui.dashboard.json

