drbd_packages:
  pkg.installed:
    - name: drbd-utils

# Mask legacy SysV wrapper drbd.service to prevent boot-time errors on Leap 16
drbd.service:
  service.masked

# Target for multi-machine/single-node DRBD resource
drbd@r0.target:
  service.enabled:
    - enable: true
    - require:
        - pkg: drbd_packages

/etc/systemd/system/var-lib-libvirt-images.mount:
  file.managed:
    - source: salt://libvirt/var-lib-libvirt-images.mount
    - mode: "0644"

/etc/systemd/system/etc-libvirt.mount:
  file.managed:
    - source: salt://libvirt/etc-libvirt.mount
    - mode: "0644"

systemd_reload_drbd:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
        - file: /etc/systemd/system/var-lib-libvirt-images.mount
        - file: /etc/systemd/system/etc-libvirt.mount

enable_var_lib_libvirt_images_mount:
  service.running:
    - name: var-lib-libvirt-images.mount
    - enable: true
    - require:
        - file: /etc/systemd/system/var-lib-libvirt-images.mount
        - service: drbd@r0.target
        - module: systemd_reload_drbd

enable_etc_libvirt_mount:
  service.running:
    - name: etc-libvirt.mount
    - enable: true
    - require:
        - file: /etc/systemd/system/etc-libvirt.mount
        - service: drbd@r0.target
        - module: systemd_reload_drbd
