/var/lib/libvirt/images:
  mount.mounted:
    - device: {{ pillar['libvirtd-image-partitions'][grains['fqdn']] }}
    - fstype: ext4
    - opts: rw,nobarrier,data=writeback
    - pass_num: 0
    - require:
      - file: /etc/fstab
