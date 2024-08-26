utilities.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
        - git-core  # not present on machines of all roles anyways
        - smartmontools  # to check SMART values of disks

/opt/retry:
  git.latest:
    - name: https://github.com/okurz/retry.git
    - target: /opt/retry
    - depth: 1
    - rev: main

/usr/local/bin/retry:
  file.symlink:
    - target: /opt/retry/retry
