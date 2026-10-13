telegraf.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - telegraf # to collect metrics
      - iputils # ping for telegraf

/etc/telegraf/telegraf.conf:
  file.managed:
    - template: jinja
    - source: salt://monitoring/telegraf/telegraf-common.conf
    - user: root
    - group: root
    - mode: "0600"
    - require:
      - pkg: telegraf.packages

/etc/systemd/system/telegraf.service:
  file.managed:
    - source: salt://monitoring/telegraf/telegraf.service
    - require:
      - pkg: telegraf.packages

{%- if not grains.get('noservices', False) %}
telegraf:
  service.running:
    - enable: true
    - watch:
      - file: /etc/telegraf/telegraf.conf
    {%- if grains.get('roles', '') in ['webui', 'worker'] %}
      - file: /etc/telegraf/telegraf.d/*
    {%- endif %}
{%- endif %}

/etc/telegraf/scripts/telegraf_config_check.sh:
  file.managed:
    - source: salt://monitoring/telegraf/scripts/telegraf_config_check.sh
    - user: root
    - group: root
    - mode: "0700"
    - makedirs: true
    - require:
      - pkg: telegraf.packages

{% for unit in ['telegraf-config-check.service', 'telegraf-config-check.path', 'telegraf-config-check.timer'] %}
/etc/systemd/system/{{ unit }}:
  file.managed:
    - source: salt://monitoring/telegraf/{{ unit }}
    - require:
      - pkg: telegraf.packages
{%- if not grains.get('noservices', False) %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/{{ unit }}
{%- endif %}
{% endfor %}

{%- if not grains.get('noservices', False) %}
telegraf-config-check.path:
  service.running:
    - enable: true
    - require:
      - file: /etc/systemd/system/telegraf-config-check.path

telegraf-config-check.timer:
  service.running:
    - enable: true
    - require:
      - file: /etc/systemd/system/telegraf-config-check.timer
{%- endif %}

/etc/telegraf/scripts/systemd_list_service_by_state_for_telegraf.sh:
  file.managed:
    - source: salt://monitoring/telegraf/scripts/systemd_list_service_by_state_for_telegraf.sh
    - user: root
    - group: root
    - mode: "0700"
    - makedirs: true
    - require:
      - pkg: telegraf.packages

