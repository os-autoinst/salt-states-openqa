# MTU for this network is 1360 bytes
/etc/sysconfig/network/ifcfg-{{ grains["default_interface"] }}:
  file.keyvalue:
    - append_if_not_found: True
    - separator: '='
    - key_values:
        MTU: "1360"
