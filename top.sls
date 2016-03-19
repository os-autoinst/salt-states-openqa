base:
  '*':
    - salt.minion
#    - sshd don't deploy till everthing is ready
  'openqa.suse.de':
    - salt.master
#    - openqa.server
  'openqaworker*':
    - sshd
# sshd only here for testing, only screw up the new machines :)
    - openqa.worker
    - openqa.scripts
  'openqaw?.qa.suse.de':
    - sshd
# sshd only here for testing, only screw up the new machines :)
    - openqa.worker
    - openqa.scripts

