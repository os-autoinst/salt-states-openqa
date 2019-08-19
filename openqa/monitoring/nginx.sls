nginx:
  pkg.latest:
    - refresh: True
    - pkgs:
      - nginx
