/etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf:
  file.managed:
    - source: salt://libvirt/libvirtd.service.conf
    - makedirs: true

{%- if not grains.get('noservices', False) %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
        - file: /etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf

# Mask all sockets to avoid accidental activation. According to a comment in libvirtd.service,
# this is the expected way to go back to "a traditional non-activation deployment setup".
{%- for socket_service in ["libvirtd-admin", "libvirtd", "libvirtd-ro"] %}
mask_libvirtd_socket_{{ socket_service }}:
  service.masked:
    - name: {{ socket_service }}.socket
    - runtime: True
{%- endfor %}

libvirtd:
  service.running:
    - enable: True
{%- endif %}

/var/lib/libvirt/images:
  mount.mounted:
    - device: {{ pillar['libvirtd-image-partitions'][grains['fqdn']] }}
    - fstype: ext4
    - opts: rw,nobarrier,data=writeback
    - pass_num: 0
