base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
    - openqa.server
  'openqaworker3.suse.de':
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
  'malbec.arch.suse.de':
    - openqa.worker

