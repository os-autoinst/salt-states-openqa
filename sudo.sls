sudo:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
