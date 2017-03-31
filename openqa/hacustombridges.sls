/etc/sysconfig/network/ifcfg-br0:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - BOOTPROTO='dhcp'
      - BRIDGE='yes'
      - BRIDGE_FORWARDDELAY='0'
      - BRIDGE_PORTS='eth0'
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

{% for i in ['br0','br2','br3'] %}
wicked ifup {{ i }}:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/network/ifcfg-{{ i }}
{% endfor %}
