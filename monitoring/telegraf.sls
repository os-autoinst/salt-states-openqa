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
    - mode: 600
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
    - enable: True
    {%- if grains.get('roles', '') in ['webui', 'worker'] %}
    - watch:
      - file: /etc/telegraf/telegraf.conf
      - file: /etc/telegraf/telegraf.d/*
    {%- endif %}
{%- endif %}

/etc/telegraf/scripts/systemd_list_service_by_state_for_telegraf.sh:
  file.managed:
    - source: salt://monitoring/telegraf/scripts/systemd_list_service_by_state_for_telegraf.sh
    - user: root
    - group: root
    - mode: 700
    - makedirs: True
    - require:
      - pkg: telegraf.packages

