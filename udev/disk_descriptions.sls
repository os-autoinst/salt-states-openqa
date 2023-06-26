/etc/udev/rules.d/80-disk-description.rules:
  file.managed:
    - template: jinja
    - source: salt://udev/80-disk-descriptions.rules.template
    - user: root
    - group: root
    - mode: '0644'
    - makedirs: True
{%- if not grains.get('noservices', False) %}
  cmd.run:
    - name: 'udevadm trigger'
    - onchanges:
      - file: /etc/udev/rules.d/80-disk-description.rules
{%- endif %}
