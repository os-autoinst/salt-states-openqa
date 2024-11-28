{%- if grains.get('needs_wireguard', 'nue2.suse.org' in grains.get('domain')) %}
include:
  - .setup-tunnel
  - .source-based-routing
{%- endif %}
