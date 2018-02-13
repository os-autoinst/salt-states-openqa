base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
    - openqa.server
    - openqa.links
  'openqaworker3.suse.de':
    - openqa.openvswitch
    - openqa.hacustombridges
  'openqaworker8.suse.de,openqaworker9.suse.de':
    - match: list
    - openqa.openvswitch
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
  'powerqaworker-qam-1':
    - openqa.worker
  'QA-Power8-5-kvm.qa.suse.de':
    - openqa.worker
  'malbec.arch.suse.de':
    - openqa.worker
  'openqaworker-arm-1.suse.de':
    - openqa.scripts
    - openqa.worker
    - openqa.openvswitch
