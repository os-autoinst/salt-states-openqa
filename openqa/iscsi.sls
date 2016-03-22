# iSCSI setup for openqaworker - currently only supports openqaworker2

# Install iscsi target package
tgt:
  pkg.installed:
    - refresh: 1

# Configure iscsi target service
tgtd:
  service.running:
    - enable: True
    - require:
      - pkg: tgt

# Create openqa-iscsi-disk file if it doesn't exist
dd if=/dev/zero of=/opt/openqa-iscsi-disk seek=1M bs=20480 count=1:
  cmd.run:
    - creates: /opt/openqa-iscsi-disk
    - require:
      - pkg: tgt

salt://openqa/iscsi-target-setup.sh:
  cmd.script:
    - creates: /etc/tgt/conf.d/openqa-scsi-target.conf
    - require:
      - cmd: dd if=/dev/zero of=/opt/openqa-iscsi-disk seek=1M bs=20480 count=1
