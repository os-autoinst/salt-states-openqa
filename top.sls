base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
    - etc.master
    - openqa.server
    - openqa.links
  'openqaworker3.suse.de':
    - openqa.hacustombridges
    - openqa.monitoring.nrpe
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
    - openqa.monitoring.nrpe
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
    - openqa.monitoring.nrpe
  'powerqaworker-qam-1':
    - openqa.worker
    - openqa.monitoring.nrpe
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.worker
    - openqa.openvswitch
    - openqa.monitoring.nrpe
  'malbec.arch.suse.de':
    - openqa.worker
    - openqa.openvswitch
    - openqa.monitoring.nrpe
  'grenache-1.qa.suse.de':
    - openqa.worker
    - openqa.monitoring.nrpe

