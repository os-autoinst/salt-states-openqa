mine_functions:
  network.interfaces: []
  grains.item:
    - nodename
    - fqdn
  nodename:
    - mine_function: grains.get
    - nodename
