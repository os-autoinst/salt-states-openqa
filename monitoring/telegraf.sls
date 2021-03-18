telegraf.packages:
  pkg.installed:
    - refresh: False
    - retry: True  # some packages can change rapidly in our repos needing a retry as zypper does not do that
    - pkgs:
      - telegraf # to collect metrics
      - iputils # ping for telegraf

/usr/lib/systemd/system/telegraf.service:
  file.managed:
    - name: /usr/lib/systemd/system/telegraf.service
    - source:
      - salt://monitoring/telegraf/telegraf.service
    - require:
      - pkg: telegraf.packages

{%- if not grains.get('noservices', False) %}
telegraf:
  service.running:
    - enable: True
    {%- if grains.get('roles', '') in ['webui', 'worker'] %}
    - watch:
      - file: /etc/telegraf/telegraf.conf
    {%- endif %}
{%- endif %}

/etc/telegraf/scripts/systemd_failed.sh:
  file.managed:
    - name: /etc/telegraf/scripts/systemd_failed.sh
    - source:
      - salt://monitoring/telegraf/scripts/systemd_failed.sh
    - user: root
    - group: root
    - mode: 700
    - makedirs: True
    - require:
      - pkg: telegraf.packages

