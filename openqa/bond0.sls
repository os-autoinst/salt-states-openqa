# New openQA workers have bonded 10Gbps ethernet connections
/etc/sysconfig/network/ifcfg-bond0:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='dhcp'
      - STARTMODE='onboot'
      - USERCONTROL='no'
      - BONDING_MASTER='yes'
      - BONDING_MODULE_OPTS='mode=4 miimon=100'
      - BONDING_SLAVE0='eth2'
      - BONDING_SLAVE1='eth3'

wicked ifup bond0:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-bond0 # if bond config changes, ifup it
    - require:
      - file: /etc/sysconfig/network/ifcfg-eth0 # don't ifup the bond if old configs lying around
      - file: /etc/sysconfig/network/ifcfg-eth1 # don't ifup the bond if old configs lying around

/etc/sysconfig/network/ifcfg-eth0:
  file.absent:
    - require:
      - file: /etc/sysconfig/network/ifcfg-bond0

/etc/sysconfig/network/ifcfg-eth1:
  file.absent:
    - require:
      - file: /etc/sysconfig/network/ifcfg-bond0
