/usr/local/bin/cleanup-openqa-assets:
  file.managed:
    - source: salt://libvirt/cleanup-openqa-assets
    - mode: '0755'
{%- if not grains.get('noservices', False) %}
  cron.present:
    - user: root
    - minute: '*/10'
{%- endif %}
