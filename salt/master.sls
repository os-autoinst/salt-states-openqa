salt-master:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5

# see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
/etc/salt/master:
  file.replace:
    - pattern: '^(server_id_use_crc: )(.*)$'
    - repl: 'server_id_use_crc: adler32'
    - append_if_not_found: true

# Prevent slow machines to run into timeout in their response
# https://progress.opensuse.org/issues/58956
# also enable:
#  - ext_pillar
#  - ipv6
master_config:
  file.serialize:
    - name: /etc/salt/master
    - serializer: yaml
    - merge_if_exists: true
    - dataset:
        interface: "::"
        ipv6: true
        timeout: 120
        ext_pillar:
          - file_tree:
              root_dir: /srv/pillar
          - nodegroups:
              pillar_name: 'nodegroups'
        nodegroups:
          all: '*'
        master_stats: True
        master_stats_event_iter: 60
        # Reduce noisy events
        auth_events: False
        minion_data_cache_events: False
        # Remove connection caching
        con_cache: False
        # Async strategy threshold
        batch_async:
            threshold: 2
        # Key rotation policy
        rotate_aes_key: False
