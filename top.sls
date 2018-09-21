base:
  '*':
    - salt.minion
    - sshd
    - openqa.monitoring.monitoring
  'openqa.suse.de':
    - salt.master
    - etc.master
    - openqa.server
    - openqa.links
  'openqaworker3.suse.de':
    - openqa.hacustombridges
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
  'powerqaworker-qam-1':
    - openqa.worker
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.worker
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
  'malbec.arch.suse.de':
    - openqa.worker
    - openqa.monitoring.metrics
    - openqa.monitoring.nrpe
