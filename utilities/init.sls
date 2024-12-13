utilities.packages:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - git-core  # not present on machines of all roles anyways
        - retry  # to have the ability to retry things without failing
        - smartmontools  # to check SMART values of disks
