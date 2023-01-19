base:
  '*':
    - network
    - salt.minion
    - sshd
    - sysctl
    - chrony
    - auto-update
    - kdump
    - monitoring.telegraf
    - udev.disk_descriptions
    - logging
  # velociraptor in https://build.opensuse.org/project/show/security:sensor
  # currently only available in x86_64
  'G@osarch:x86_64':
    - security_sensor
  'G@roles:webui':
    - salt.master
    - etc.master
    - openqa.server
    - openqa.links
    - openqa.openqa-trigger-from-ibs
    - certificates.dehydrated
  'G@roles:worker':
    - openqa.repos
    - openqa.worker
    - openqa.nvme_store
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
    - openqa.openvswitch_boo1181418
    - openqa.dbus
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'G@roles:worker and G@osarch:aarch64':
    - haveged
  'G@roles:monitor':
    - monitoring.maintenance_queue
    - monitoring.grafana
    - monitoring.influxdb
    - certificates.dehydrated
  'G@roles:storage':
    - backup.rsnapshot
