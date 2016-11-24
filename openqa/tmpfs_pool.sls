/var/lib/openqa/pool:
  mount.mounted:
    - device: tmpfs
    - opts: noatime,nodev,nosuid,size=91G
    - fstype: tmpfs
    - require:
      - pkg: worker-openqa.packages

