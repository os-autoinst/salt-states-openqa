/etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf:
  file.managed:
    - source: salt://libvirt/libvirtd.service.conf
    - makedirs: true

{%- if not grains.get('noservices', False) %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
        - file: /etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf

libvirtd.socket:
  service.running:
    - enable: True
{%- endif %}

{%- set zfcp_adapters = salt['pillar.get']('zfcp-adapters', {}).get(grains['host'], []) %}
{%- if grains.get('osarch') == 's390x' and zfcp_adapters %}
multipathd:
  service.running:
    - enable: True

{%- for adapter in zfcp_adapters %}
zfcp_cio_ignore_{{ adapter }}:
  cmd.run:
    - name: cio_ignore -r {{ adapter }}
    - unless: test -d /sys/bus/ccw/devices/{{ adapter }}

zfcp_online_{{ adapter }}:
  cmd.run:
    - name: zfcp_host_configure {{ adapter }} 1
    - unless: test "$(cat /sys/bus/ccw/devices/{{ adapter }}/online 2>/dev/null)" = "1"
{%- endfor %}
{%- endif %}

{%- set image_partitions = salt['pillar.get']('libvirtd-image-partitions', {}) %}
{%- if grains['fqdn'] in image_partitions %}
/var/lib/libvirt/images:
  mount.mounted:
    - device: {{ image_partitions[grains['fqdn']] }}
    - fstype: ext4
    - opts: rw,nobarrier,data=writeback
    - pass_num: 0
{%- endif %}
