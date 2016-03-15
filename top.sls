base:
  '*':
    - salt.minion
#    - sshd
  'openqa.suse.de'
    - salt.master
#    - openqa.server
#  'openqaworker*'
#    - openqa.worker