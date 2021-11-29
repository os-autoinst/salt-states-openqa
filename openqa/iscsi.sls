# iSCSI setup for openqaworker - currently only supports openqaworker2

qemu:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# Coolo says we shouldn't do this - kernel should be packaged
/usr/share/qemu/ipxe.lkrn:
  file.managed:
    - source: salt://openqa/ipxe.lkrn

# Install iscsi target package
tgt:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# Create openqa-iscsi-disk file if it doesn't exist
dd if=/dev/zero of=/opt/openqa-iscsi-disk seek=1M bs=20480 count=1:
  cmd.run:
    - creates: /opt/openqa-iscsi-disk
    - require:
      - pkg: tgt

# Configure iscsi target service
{%- if not grains.get('noservices', False) %}
tgtd:
  service.running:
    - enable: True
    - require:
      - pkg: tgt

salt://openqa/iscsi-target-setup.sh:
  cmd.script:
    - creates: /etc/tgt/conf.d/openqa-scsi-target.conf
    - require:
      - cmd: dd if=/dev/zero of=/opt/openqa-iscsi-disk seek=1M bs=20480 count=1
{%- endif %}
