saltmaster.packages:
  pkg.installed:
    - pkgs:
      - salt-master

git -C /srv/salt pull >/dev/null 2>&1:
  cron.present:
    - user: root
    - minute: '*/5'
    
git -C /srv/pillar pull >/dev/null 2>&1:
  cron.present:
    - user: root
    - minute: '*/5'

# see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
/etc/salt/master:
  file.replace:
    - pattern: '^(server_id_use_crc: )(.*)$'
    - repl: 'server_id_use_crc: adler32'
    - append_if_not_found: True
