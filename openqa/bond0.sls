# New openQA workers have bonded 10Gbps ethernet connections
/etc/sysconfig/network/ifcfg-bond0:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='none'
      - STARTMODE='auto'
      - USERCONTROL='no'
      - BONDING_MASTER='yes'
      - BONDING_MODULE_OPTS='mode=4 miimon=100'
      - BONDING_SLAVE0='eth2'
      - BONDING_SLAVE1='eth3'

/etc/sysconfig/network/ifcfg-br0:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='dhcp'
      - BRIDGE='yes'
      - BRIDGE_FORWARDDELAY='0'
      - BRIDGE_PORTS='bond0'
      - BRIDGE_STP='off'
      - BROADCAST=''
      - DHCLIENT_SET_DEFAULT_ROUTE='yes'
      - STARTMODE='auto'

/etc/sysconfig/network/ifcfg-br2:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='none'
      - BRIDGE='yes'
      - BRIDGE_FORWARDDELAY='0'
      - BRIDGE_PORTS=''
      - BRIDGE_STP='off'
      - BROADCAST=''
      - DHCLIENT_SET_DEFAULT_ROUTE='yes'
      - STARTMODE='auto'

/etc/sysconfig/network/ifcfg-br3:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='none'
      - BRIDGE='yes'
      - BRIDGE_FORWARDDELAY='0'
      - BRIDGE_PORTS=''
      - BRIDGE_STP='off'
      - BROADCAST=''
      - DHCLIENT_SET_DEFAULT_ROUTE='yes'
      - STARTMODE='auto'

wicked ifup br0:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br0 # if br1 config changes, ifup it
    - require:
      - file: /etc/sysconfig/network/ifcfg-bond0 # bond needs to be there before you can use bridge with it
      - file: /etc/sysconfig/network/ifcfg-eth0 # don't ifup the bond if old configs lying around
      - file: /etc/sysconfig/network/ifcfg-eth1 # don't ifup the bond if old configs lying around
      
wicked ifup br2:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br2 # if br2 config changes, ifup it
      
wicked ifup br3:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-br3 # if br3 config changes, ifup it

/etc/sysconfig/network/ifcfg-eth0:
  file.absent:
    - require:
      - file: /etc/sysconfig/network/ifcfg-bond0

/etc/sysconfig/network/ifcfg-eth1:
  file.absent:
    - require:
      - file: /etc/sysconfig/network/ifcfg-bond0
