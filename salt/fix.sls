patch:
  pkg.installed

# See https://progress.opensuse.org/issues/54458
# and https://github.com/aplanas/salt/commit/0315a25cf38a4c001008a3e68917b4611e368197
/usr/lib/python3.6/site-packages/salt/grains/core.py:
  file.patch:
    - source: salt://salt/ignore_host_not_found.patch
    - hash: md5=8dd403bafbf324fb2d83fb0b5b9b38a1
    - strip: 1
