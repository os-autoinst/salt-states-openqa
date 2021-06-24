salt-master:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
/etc/salt/master:
  file.replace:
    - pattern: '^(server_id_use_crc: )(.*)$'
    - repl: 'server_id_use_crc: adler32'
    - append_if_not_found: True

# Prevent slow machines to run into timeout in their response
# https://progress.opensuse.org/issues/58956
# and ext_pillar
master_config:
  file.append:
    - name: /etc/salt/master
    - text: |
        timeout: 90
        ext_pillar:
          - file_tree:
              root_dir: /srv/pillar
