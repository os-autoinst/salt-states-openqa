# apply for all NVMes which are not the only storage
{% if grains['SSDs']|map('regex_search', '(nvme)')|select|list|length > 0 and grains['disks']|length > 0 %}
server.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - mdadm

/etc/systemd/system/openqa_nvme_format.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_format.service
    - source:
      - salt://openqa/nvme_store/openqa_nvme_format.service

/etc/systemd/system/openqa_nvme_prepare.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_prepare.service
    - source:
      - salt://openqa/nvme_store/openqa_nvme_prepare.service

/etc/systemd/system/openqa-worker@.service.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/openqa-worker@.service.d/override.conf
    - source:
      - salt://openqa/nvme_store/openqa-worker@_override.conf
    - makedirs: true

# ensure old device entries are removed
/etc/fstab:
  file.comment:
    - regex: UUID.*/var/lib/openqa(?!/share)

/var/lib/openqa:
  mount.mounted:
    - device: /dev/md0
    - fstype: ext2
    - mkmnt: True
    # the mount should only be done at boot time as we depend on device
    # preparation
    - mount: False

/etc/systemd/system/var-lib-openqa.mount.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/var-lib-openqa.mount.d/override.conf
    - source:
      - salt://openqa/nvme_store/var-lib-openqa.mount_override.conf
    - makedirs: true

daemon-reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/var-lib-openqa.mount.d/override.conf
      - file: /etc/systemd/system/openqa-worker@.service.d/override.conf
      - file: /etc/systemd/system/openqa_nvme_format.service
      - file: /etc/systemd/system/openqa_nvme_prepare.service
{% endif %}
