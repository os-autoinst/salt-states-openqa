/opt/retry:
  git.latest:
    - name: https://github.com/okurz/retry.git
    - target: /opt/retry
    - depth: 1
    - rev: main

/usr/local/bin/retry:
  file.symlink:
    - target: /opt/retry/retry
