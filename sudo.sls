sudo:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5
