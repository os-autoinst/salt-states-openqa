/etc/iproute2/rt_tables:
  file.append:
    - text: '240     nowg'

/usr/local/bin/configure-source-based-routing:
  file.managed:
    - mode: "0755"
    - source: salt://wireguard/configure-source-based-routing
    - makedirs: true

/etc/systemd/system/configure-source-based-routing@.service:
  file.managed:
      - create: true
          - contents: |
              [Unit]
              Description=Wicked hook service to configure source based routing for %i

              [Service]
              Type=oneshot
              ExecStart=/usr/local/bin/configure-source-based-routing %i

{%- if not grains.get('noservices', False) %}
configure-source-based-routing service reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/configure-source-based-routing@.service
{% endif %}
