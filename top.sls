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
  'openqaworker*':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.openvswitch
  'openqaw?.qa.suse.de':
    - openqa.worker
    - openqa.scripts
    - openqa.iscsi
    - openqa.tmpfs_pool
  'powerqaworker-qam-1':
    - openqa.worker
  'QA-Power8-*-kvm.qa.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'malbec.arch.suse.de':
    - openqa.worker
    - openqa.openvswitch
  'grenache-1.qa.suse.de':
    - openqa.worker
  'openqaworker-arm-2':
    - openqa.nvme_reformat.deploy-services
