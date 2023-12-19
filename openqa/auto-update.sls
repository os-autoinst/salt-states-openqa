{%- if not grains.get('noservices', False) %}
/usr/local/bin/auto-update:
  file.managed:
    - mode: "0755"
    - source: salt://openqa/auto-update.sh

{% for type in ['service', 'timer'] %}
auto_update_{{ type }}:
  file.managed:
    - name: /etc/systemd/system/auto-update.{{ type }}
    - source: salt://openqa/auto-update.{{ type }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_update_{{ type }}

auto-upgrade.{{ type }}:
  service.dead:
    - enable: False
{% endfor %}

auto-update.timer:
  service.running:
    - enable: True
    - require:
      - auto_update_timer
{%- endif %}
