mine_functions:
  network.interfaces: []
  grains.item:
    - nodename
    - fqdn
    - ip4_interfaces
  nodename:
    - mine_function: grains.get
    - nodename
  ip4_interfaces:
    - mine_function: grains.get
    - ip4_interfaces
