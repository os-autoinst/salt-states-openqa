# MTU for this network is 1360 bytes
network_mtu:
  file.keyvalue:
    - name: /etc/sysconfig/network/ifcfg-{{ grains["default_interface"] }}
    - append_if_not_found: True
    - separator: '='
    - key_values:
        MTU: "1360"
