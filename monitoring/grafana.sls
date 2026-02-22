{% set dashboard_template_folder = '/var/lib/grafana/dashboards' %}


{% set workernames = salt['mine.get']('roles:worker', 'nodename', tgt_type='grain').values()|list %} #list of all worker names (no fqdn, just the name)
{% set worker_dashboardnames = (workernames | map('regex_replace', '^(.*)$', 'worker-\\1.json'))|list %} #we name our dashboards "worker-$nodename.json"
{% set templated_dashboardnames = ['webui.services.json', 'certificates.json'] %}
{% set manual_dashboardnames = ['webui.dashboard.json', 'failed_systemd_services.json', 'automatic_actions.json', 'job_age.json', 'openqa_jobs.json', 'status_overview.json', 'monitoring.json', 'maintenance_update_queue.json', 'agile.dashboard.json', 'sap_perf_gitlab_commits.json', 'sleperf_metrics.json', 'deploy_runtime.json'] %}
{% set genericnames = salt['mine.get']('not G@roles:webui and not G@roles:worker', 'nodename', tgt_type='compound').values()|list %} #list names of all generic hosts
{% set generic_dashboardnames = (genericnames | map('regex_replace', '^(.*)$', 'generic-\\1.json'))|list %} #we name our dashboards for generic hosts "generic-$nodename.json"
{% set grafana_plugins = ['grafana-image-renderer', 'blackmirror1-singlestat-math-panel'] %}
{% set preserved_dashboards = worker_dashboardnames + generic_dashboardnames + templated_dashboardnames + manual_dashboardnames %}
{% set services_for_templated_dashboards = 'sshd openqa-gru openqa-webui openqa-livehandler openqa-scheduler openqa-websockets smb vsftpd telegraf salt-master salt-minion rsyncd postgresql postfix cron nginx' %}
{% set provisioned_alerts = ['stacked-backlog-no-data.yaml', 'dashboard-automatic-actions.yaml', 'failed-systemd-services.yaml', 'dashboard-job-age.yaml', 'dashboard-monitoring.yaml', 'dashboard-openqa-jobs-test.yaml', 'dashboard-WebuiDb.yaml', 'inodes.yaml', 'http_response_codes.yaml', 'network-availability.yaml', 'deployment-run-time.yaml', 'bot-ng.yaml'] %}

grafana:
  pkg.latest:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5

/etc/tmpfiles.d/grafana.conf:
  file.managed:
    - contents:
      - 'd      /run/grafana            0770 root grafana -'

'systemd-tmpfiles --create':
  cmd.run:
    - onchanges:
      - file: /etc/tmpfiles.d/grafana.conf

/usr/local/bin/reload-grafana.sh:
  file.managed:
    - source: salt://monitoring/grafana/reload_grafana.sh
    - mode: "0755"

{%- if not grains.get('noservices', False) %}
{% for grafana_overwrite in ['00-enable-reload', '01-service-fail-mail'] %}
/etc/systemd/system/grafana-server.service.d/{{ grafana_overwrite }}.conf:
  file.managed:
    - source: salt://monitoring/grafana/{{ grafana_overwrite }}.conf
    - template: jinja
    - mode: "0644"
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/grafana-server.service.d/{{ grafana_overwrite }}.conf
{% endfor %}

error_mail_service:
  file.managed:
    - name: /etc/systemd/system/grafana-error-mail.service
    - source: salt://monitoring/grafana/grafana-error-mail.service
    - mode: "0644"
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: error_mail_service
{%- endif %}

include:
 - monitoring.nginx

reverse-proxy-group:
  group.present:
  - addusers:
    - nginx
  - require:
    - nginx

/etc/grafana/grafana.ini:
  ini.options_present:
    - separator: '='
    - strict: True
    - sections:
        server:
          protocol: socket
          domain: 'monitor.qa.suse.de'
          root_url: 'https://monitor.qa.suse.de'
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
        auth.ldap:
          enabled: true
          config_file: '/etc/grafana/ldap.toml'
          skip_org_role_sync: true
        smtp:
          enabled: true
          host: 'localhost:25'
          from_address: 'osd-admins@suse.de'
          from_name: 'Grafana'
        security:
          allow_embedding: true
        panels:
          disable_sanitize_html: true
        unified_alerting:
          enabled: true
        date_formats:
          default_timezone: 'UTC'
        feature_toggles:
          enable: panelTitleSearch

/etc/grafana/ldap.toml:
  file.managed:
    - source: salt://monitoring/grafana/ldap.toml
    - mode: "0644"

/etc/grafana/provisioning/dashboards/salt.yaml:
  file.managed:
    - source: salt://monitoring/grafana/salt.yaml

{% for provisioned_alert in provisioned_alerts %}
/etc/grafana/provisioning/alerting/{{ provisioned_alert }}:
  file.managed:
    - makedirs: True
    - mode: "0644"
    - source: salt://monitoring/grafana/alerting/{{ provisioned_alert }}
{% endfor %}

{% for plugin in grafana_plugins %}
install_{{ plugin }}:
  cmd.run:
    - name: /usr/sbin/grafana-cli plugins install {{ plugin }}
    - runas: grafana
    - creates: /var/lib/grafana/plugins/{{ plugin }}
{% endfor %}

#remove all dashboards which are not preserved (see manual_dashboardnames above)
#and that do not appear in the mine anymore (e.g. decommissioned workers)
dashboard-cleanup:
{% if preserved_dashboards|length > 0 %}
  cmd.run: #this find statement only works if we have at least one dashboard to preserve
    - cwd: {{ dashboard_template_folder }}
    - name: find -type f ! -name {{ preserved_dashboards|join(' ! -name ') }} -delete
{% else %}
  file.directory: #if we have absolutely no node, just purge the folder
    - name: {{ dashboard_template_folder }}
    - clean: True
{% endif %}

#create dashboards manually defined but managed by salt
{% for manual_dashboardname in manual_dashboardnames %}
{{ "/".join([dashboard_template_folder, manual_dashboardname]) }}: #works even if variables already contain slashes
  file.managed:
    - source: salt://monitoring/grafana/{{ manual_dashboardname }}
{% endfor %}

#create templated dashboards
{% for templated_dashboardname in templated_dashboardnames %}
{{ "/".join([dashboard_template_folder, templated_dashboardname]) }}: #works even if variables already contain slashes
  file.managed:
    - source: salt://monitoring/grafana/{{ templated_dashboardname }}.template
    - template: jinja
    - services: {{ services_for_templated_dashboards }}

{% set provisioned_alert = templated_dashboardname | replace(".json", ".yaml") %}
/etc/grafana/provisioning/alerting/dashboard-{{ provisioned_alert }}:
  file.managed:
    - source: salt://monitoring/grafana/alerting/templates/{{ provisioned_alert }}.template
    - template: jinja
    - services: {{ services_for_templated_dashboards }}
{% do provisioned_alerts.append('dashboard-' + provisioned_alert) %}
{% endfor %}

#create dashboards and alerts for each worker contained in the mine
#iterating over worker_dashboardnames would be cleaner but we need the workername itself for the template
{% for workername in workernames -%}
{% set host_interface = salt['mine.get']("nodename:" + workername, 'network.interfaces', 'grain').keys()|first|default() %}
{{ "/".join([dashboard_template_folder, "worker-" + workername + ".json"]) }}: #same as for manual dashboards too
  file.managed:
    - source: salt://monitoring/grafana/worker.json.template
    - mode: "0644"
    - template: jinja
    - worker: {{ workername }}
    - host_interface: {{ host_interface }}

/etc/grafana/provisioning/alerting/dashboard-WD{{ workername }}.yaml:
  file.managed:
    - source: salt://monitoring/grafana/alerting/templates/worker-alerts.yaml.template
    - mode: "0644"
    - template: jinja
    - worker: {{ workername }}
    - host_interface: {{ host_interface }}
{% do provisioned_alerts.append('dashboard-WD' + workername + '.yaml') %}
{% endfor %}

#create dashboards for each generic host contained in the mine
{% for genericname in genericnames -%}
{% set host_interface = salt['mine.get']("nodename:" + genericname, 'network.interfaces', 'grain').keys()|first|default() %}
{{ "/".join([dashboard_template_folder, "generic-" + genericname + ".json"]) }}: #same as for manual dashboards too
  file.managed:
    - source: salt://monitoring/grafana/generic.json.template
    - mode: "0644"
    - template: jinja
    - generic_host: {{ genericname }}
    - host_interface: {{ host_interface }}

/etc/grafana/provisioning/alerting/dashboard-GD{{ genericname }}.yaml:
  file.managed:
    - source: salt://monitoring/grafana/alerting/templates/generic-machine-alerts.yaml.template
    - mode: "0644"
    - template: jinja
    - generic_host: {{ genericname }}
    - host_interface: {{ host_interface }}
{% do provisioned_alerts.append('dashboard-GD' + genericname + '.yaml') %}
{% endfor %}

# remove all alerts which are not provisioned anymore
alert-cleanup:
{% set provisioned_alerts_folder = '/etc/grafana/provisioning/alerting' %}
{% if provisioned_alerts | length > 0 %}
  cmd.run:
    - cwd: {{ provisioned_alerts_folder }}
    - name: find -type f ! -name {{ provisioned_alerts | join(' ! -name ') }} -delete
{% else %}
  file.directory:
    - name: {{ provisioned_alerts_folder }}
    - clean: True
{% endif %}

# remove alerts explicitly mentioned by a deletionRule
/etc/grafana/provisioning/alerting/alerts_to_delete.yaml:
  file.managed:
    - source: salt://monitoring/grafana/alerting/alerts_to_delete.yaml
    - mode: "0644"

{%- if not grains.get('noservices', False) %}
grafana-server:
  service.running:
    - enable: True
    - reload: True
    - watch:
{% for plugin in grafana_plugins %}
      - cmd: install_{{ plugin }}
{% endfor %}
      - file: /etc/grafana/*
      - file: {{ dashboard_template_folder }}*
{%- endif %}
