base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
    - openqa.server
  'openqaworker2.suse.de':
    - openqa.bond0
  'openqaworker3.suse.de':
    - openqa.bond0
  'openqaworker4.suse.de':
    - openqa.bond0
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi

