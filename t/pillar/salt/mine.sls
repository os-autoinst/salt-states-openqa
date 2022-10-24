mine_functions:
  network.interfaces: []
  grains.item:
    - nodename
    - fqdn
    - fqdn_ip4
  nodename:
    - mine_function: grains.get
    - nodename
