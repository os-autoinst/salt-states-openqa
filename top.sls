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
    - openqa.nvme_store
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
  'openqaworker3.suse.de':
    - openqa.hacustombridges
  'G@roles:worker and G@osarch:aarch64':
    - haveged
  'G@roles:monitor':
    - openqa.monitoring.grafana
    - openqa.monitoring.influxdb
