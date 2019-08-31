base:
  '*':
    - salt.minion
    - sshd
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
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
  'powerqaworker-qam-1':
    - openqa.worker
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'malbec.arch.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'grenache-1.qa.suse.de':
    - openqa.worker
  'openqaworker-arm-*':
    - openqa.nvme_reformat.deploy-services
    - haveged
  'openqa-monitor.qa.suse.de':
    - openqa.monitoring.grafana
    - openqa.monitoring.influxdb
    - openqa.monitoring.nginx
