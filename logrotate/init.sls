logrotate:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/systemd/system/logrotate.service.d/override.conf:
  file.managed:
    - source: salt://logrotate/override.conf
    - makedirs: True

/etc/systemd/system/logrotate.timer.d/override.conf:
   file.absent

{% for type in ['service', 'timer'] %}
/etc/systemd/system/logrotate-openqa.{{ type }}:
  file.managed:
    - source: salt://logrotate/logrotate-openqa.{{ type }}
    - makedirs: true
{% endfor %}

/etc/logrotate.d/openqa-apache:
  file.managed:
    - source:
      - salt://logrotate/openqa-apache

{%- if not grains.get('noservices', False) %}
logrotate-openqa.timer:
  service.running:
    - enable: True
    - require:
      - auto_update_timer

logrotate timer reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/logrotate.service.d/override.conf
      - file: /etc/systemd/system/logrotate-openqa.service
      - file: /etc/systemd/system/logrotate-openqa.timer
{%- endif %}
