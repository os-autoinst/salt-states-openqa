base:
  '*':
    - etc.fstab
    - system.packages.locks
    - network
    - network.accept_ra
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
    - timezone_utc
  'G@needs_wireguard:True or ( *.nue2.suse.org and not G@needs_wireguard:False )':
    - wireguard
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
    - monitoring.sleperf
    - monitoring.slo
    - monitoring.yam
    - monitoring.monitoring-software-repo
    - monitoring.grafana
    - monitoring.loki
    - monitoring.influxdb
    - monitoring.certificates
    - certificates.dehydrated
  'G@roles:storage':
    - backup.rsnapshot_openqa_data
  'G@roles:backup_prg2':
    - backup.rsnapshot_generic
  'G@roles:jenkins':
    - jenkins
  'G@roles:libvirt':
    - libvirt
  'G@roles:external_openqa_hypervisor':
    - libvirt.storage
    - openqa.kvm_firewall
    - openqa.nfs_share
    - openqa.recover-nfs
  'openqa-piworker.qe.nue2.suse.org':
    - raspberrypi
  '*.nue2.suse.org':
    - network.nue2
