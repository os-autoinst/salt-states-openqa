server.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - mdadm

# apply for NVMes only
{% if grains['SSDs']|map('regex_search', '(nvme)')|select|list|length > 0 %}
/etc/systemd/system/openqa_nvme_format.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_format.service
    - mode: 644
    - source:
      - salt://openqa/nvme_store/openqa_nvme_format.service

/etc/systemd/system/openqa_nvme_prepare.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_prepare.service
    - mode: 644
    - source:
      - salt://openqa/nvme_store/openqa_nvme_prepare.service

/etc/systemd/system/openqa-worker@.service.d/20-nvme-autoformat.conf:
  file.managed:
    - name: /etc/systemd/system/openqa-worker@.service.d/20-nvme-autoformat.conf
    - mode: 644
    - source:
      - salt://openqa/nvme_store/openqa-worker@_override.conf
    - makedirs: true

/var/lib/openqa:
  mount.mounted:
    - device: /dev/md/openqa
    - fstype: ext2
    - mkmnt: True
    # the mount should only be done at boot time as we depend on device
    # preparation
    - mount: False

/etc/systemd/system/var-lib-openqa.mount.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/var-lib-openqa.mount.d/override.conf
    - mode: 644
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
