ntp:
  pkg.installed:
    - refresh: False

/etc/ntp.conf:
  file.managed:
    - source:
      - salt://ntpd/ntp.conf
    - user: root
    - group: root
    - mode: 600

{%- if not grains.get('noservices', False) %}
ntpd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/ntp.conf
{%- endif %}
