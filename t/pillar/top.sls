base:
  '*':
    - sshd.users
    - salt.mine
    - disks.descriptions
    - openqa.commonconf
    - network.sysconfig
  'G@roles:webui':
    - openqa.server
    - certificates.hosts
  'G@roles:monitor':
    - certificates.hosts
    - openqa.monitoring
  'G@roles:worker':
    - openqa.workerconf
