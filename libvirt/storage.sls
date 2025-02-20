/etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf:
  file.managed:
    - source: salt://libvirt/libvirtd.service.conf
    - makedirs: true

{%- if not grains.get('noservices', False) %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
        - file: /etc/systemd/system/libvirtd.service.d/asset-mount-requirement.conf
{%- endif %}

/var/lib/libvirt/images:
  mount.mounted:
    - device: {{ pillar['libvirtd-image-partitions'][grains['fqdn']] }}
    - fstype: ext4
    - opts: rw,nobarrier,data=writeback
    - pass_num: 0
    - require:
      - file: /etc/fstab
