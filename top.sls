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
    - utilities
    - logging
    - rebootmgr
    - etc.zypper
    - ca-certificates
    - debug_poo133469
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
    - openqa.recover-nfs
  'G@roles:webui or G@roles:worker':
    - openqa.auto-update
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'G@roles:worker and G@osarch:aarch64':
    - haveged
  'G@roles:monitor':
    - monitoring.maintenance_queue
    - monitoring.sap_perf
    - monitoring.slo
    - monitoring.yam
    - monitoring.grafana
    - monitoring.influxdb
    - certificates.dehydrated
  'G@roles:storage':
    - backup.rsnapshot
  'G@roles:jenkins':
    - jenkins
  'G@roles:libvirt':
    - libvirt
  'openqa-piworker.qa.suse.de':
    - raspberrypi.external-rtc
