/etc/systemd/system/openqa_nvme_format.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_format.service
    - source:
      - salt://openqa/nvme_store/openqa_nvme_format.service
    - user: root
    - group: root
    - mode: 600

/etc/systemd/system/openqa_nvme_prepare.service:
  file.managed:
    - name: /etc/systemd/system/openqa_nvme_prepare.service
    - source:
      - salt://openqa/nvme_store/openqa_nvme_prepare.service
    - user: root
    - group: root
    - mode: 600

/etc/systemd/system/openqa-worker@.service.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/openqa-worker@.service.d/override.conf
    - source:
      - salt://openqa/nvme_store/openqa-worker@_override.conf
    - makedirs: true
    - user: root
    - group: root
    - mode: 600

/etc/systemd/system/var-lib-openqa-nvme.mount.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/var-lib-openqa-nvme.mount.d/override.conf
    - source:
      - salt://openqa/nvme_store/var-lib-openqa-nvme.mount_override.conf
    - makedirs: true
    - user: root
    - group: root
    - mode: 600

daemon-reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/var-lib-openqa-nvme.mount.d/override.conf
      - file: /etc/systemd/system/openqa-worker@.service.d/override.conf
      - file: /etc/systemd/system/openqa_nvme_format.service
      - file: /etc/systemd/system/openqa_nvme_prepare.service
