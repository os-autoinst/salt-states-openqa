base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
    - openqa.server
  'openqaworker3.suse.de':
    - openqa.openvswitch
    - openqa.hacustombridges
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
  'QA-Power8-5-kvm.qa.suse.de':
    - openqa.worker
  'malbec.arch.suse.de':
    - openqa.worker
  'GONE-FOR-NOW-openqaworker-arm-1.suse.de':
    - openqa.scripts
    - openqa.worker
    - openqa.iscsi
    - openqa.tmpfs_pool
