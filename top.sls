base:
  '*':
    - salt.minion
    - sshd
    - auto-update
  'G@roles:webui':
    - salt.master
    - etc.master
    - openqa.repos
    - openqa.server
    - openqa.links
    - openqa.openqa-trigger-from-ibs
  'G@roles:worker':
    - openqa.repos
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'openqaworker5':
    - openqa.kvm
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.kvm
  'openqaworker-arm-*':
    - openqa.nvme_store
    - haveged
  'G@roles:monitor':
    - openqa.monitoring.grafana
    - openqa.monitoring.influxdb
