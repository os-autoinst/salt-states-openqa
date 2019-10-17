salt-minion:
  pkg.installed:
    - refresh: False

# see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
/etc/salt/minion:
  file.replace:
    - pattern: '^(server_id_use_crc: )(.*)$'
    - repl: 'server_id_use_crc: adler32'
    - append_if_not_found: True


# speed up salt a lot, see https://github.com/saltstack/salt/issues/48773#issuecomment-443599880
speedup_minion:
  file.append:
    - name: /etc/salt/minion
    - text: |
        disable_grains:
          - esxi
        
        disable_modules:
          - vsphere
        
        grains_cache: True
