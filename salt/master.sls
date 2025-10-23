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
        # Reference: https://progress.opensuse.org/issues/58956
        # Provide detailed statistics of internal Salt calls
        # Documentation can be found here:
        # https://docs.saltproject.io/en/latest/ref/configuration/master.html#master-stats
        master_stats: true
        # https://docs.saltproject.io/en/latest/ref/configuration/master.html#master-stats-event-iter
        master_stats_event_iter: 60
        # Reduce noisy events
        # https://www.uyuni-project.org/uyuni-docs/en/uyuni/specialized-guides/large-deployments/tuning.html#auth-events
        auth_events: false
        # https://www.uyuni-project.org/uyuni-docs/en/uyuni/specialized-guides/large-deployments/tuning.html#minion-data-cache-events
        minion_data_cache_events: false
