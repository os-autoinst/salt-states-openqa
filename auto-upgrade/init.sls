{%- if not grains.get('noservices', False) %}
{% for type in ['service', 'timer'] %}
auto_upgrade_{{ type }}:
  file.managed:
    - name: /etc/systemd/system/auto-upgrade.{{ type }}
    - source: salt://auto-upgrade/auto-upgrade.{{ type }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: auto_upgrade_{{ type }}
{% endfor %}

auto-upgrade.timer:
  service.running:
    - enable: True
    - require:
      - auto_upgrade_timer
{%- endif %}
