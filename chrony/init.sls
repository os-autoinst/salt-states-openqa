chrony:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

ntp:
  pkg.purged

/etc/chrony.d/suse.conf:
  file.managed:
    - source: salt://chrony/suse.conf

{%- if not grains.get('noservices', False) %}
chronyd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/chrony.d/suse.conf

ntpd:
  service.disabled
{%- endif %}
