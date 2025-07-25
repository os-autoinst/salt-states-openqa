{%- if not grains.get('noservices', False) %}
/usr/local/bin/tumblesle-fetch-jekyll:
  file.managed:
    - mode: "0755"
    - source: salt://usr/local/bin/tumblesle-fetch-jekyll

{% for type in ['service', 'timer'] %}
update_jekyll_source_{{ type }}:
  file.managed:
    - name: /etc/systemd/system/update-jekyll-source.{{ type }}
    - source: salt://etc/tumblesle/systemd/system/update-jekyll-source.{{ type }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: update_jekyll_source_{{ type }}
{% endfor %}

update-jekyll-source.timer:
  service.running:
    - enable: True
    - require:
      - update_jekyll_source_timer
{%- endif %}

