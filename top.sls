base:
  '*':
    - network
    - salt.minion
    - sshd
    - sysctl
    - chrony
    - kdump
    - monitoring.telegraf
    - security_sensor
    - udev.disk_descriptions
    - logging
    - rebootmgr
  'not G@roles:webui and not G@roles:worker':
    - auto-upgrade
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
  'G@roles:webui or G@roles:worker':
    - openqa.auto-update
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'G@roles:worker and G@osarch:aarch64':
    - haveged
  'G@roles:monitor':
    - monitoring.maintenance_queue
    - monitoring.slo
    - monitoring.grafana
    - monitoring.influxdb
    - certificates.dehydrated
  'G@roles:storage':
    - backup.rsnapshot
