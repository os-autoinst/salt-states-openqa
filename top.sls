base:
  '*':
    - salt.fix
    - salt.minion
    - sshd
    - auto-update
  'openqa.suse.de':
    - salt.master
    - etc.master
    - openqa.repos
    - openqa.server
    - openqa.links
    - openqa.openqa-trigger-from-ibs
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'openqaworker*':
    - openqa.repos
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
  'openqaworker5':
    - openqa.kvm
  'powerqaworker-qam-1':
    - openqa.worker
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'QA-Power8-4-kvm.qa.suse.de':
    - openqa.kvm
  'QA-Power8-5-kvm.qa.suse.de':
    - openqa.kvm
  'malbec.arch.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'grenache-1.qa.suse.de':
    - openqa.worker
    - openqa.kvm
  'openqaworker-arm-*':
    - openqa.nvme_store
    - haveged
    - nscd
  'openqa-monitor.qa.suse.de':
    - openqa.monitoring.grafana
    - openqa.monitoring.influxdb
    - openqa.monitoring.nginx
