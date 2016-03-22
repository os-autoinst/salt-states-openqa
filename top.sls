base:
  '*':
    - salt.minion
    - sshd
  'openqa.suse.de':
    - salt.master
#    - openqa.server
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts

