/usr/local/bin/recover-nfs.sh:
  file.managed:
    - source: salt://openqa/recover-nfs.sh
    - template: jinja
    - user: root
    - group: root
    - mode: "0744"

{%- if not grains.get('noservices', False) %}
{% for type in ['service', 'timer'] %}
recover-nfs_{{ type }}:
  file.managed:
    - name: /etc/systemd/system/recover-nfs.{{ type }}
    - source: salt://openqa/recover-nfs.{{ type }}
    - makedirs: true
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: recover-nfs_{{ type }}
{% endfor %}

recover-nfs.timer:
  service.running:
    - enable: True
{%- endif %}
