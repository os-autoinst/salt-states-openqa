salt-minion:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
{%- if not grains.get('noservices', False) %}
  service.enabled:
    - name: salt-minion
{%- endif %}

# Clean up old tuning/workaround configurations from /etc/salt/minion on existing nodes
# as they are now consolidated into /etc/salt/minion.d/99-tuning.conf
clean_old_minion_tweaks:
  file.replace:
    - name: /etc/salt/minion
    - pattern: '(?m)^(server_id_use_crc|random_reauth_delay|recon_default|recon_max|recon_randomize|master_tries|auth_safemode|multiprocessing):.*(?:\n|$)|^disable_(grains|modules):\n(?:[ \t]*- .*(?:\n|$))*'
    - repl: ''
    - ignore_if_missing: True
    - require:
      - pkg: salt-minion

# Consolidate minion tweaks into a dedicated drop-in file instead of clobbering /etc/salt/minion
minion_tuning:
  file.serialize:
    - name: /etc/salt/minion.d/99-tuning.conf
    - serializer: yaml
    - merge_if_exists: True
    - dataset:
        # see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
        server_id_use_crc: adler32

        # speed up salt a lot, see https://github.com/saltstack/salt/issues/48773#issuecomment-443599880
        disable_grains:
          - esxi
        disable_modules:
          - vsphere
        # Make minions less aggressive on re-authentication
        random_reauth_delay: 60
        recon_default: 1000
        recon_max: 29000
        recon_randomize: True
        # Make minions try to reconnect more
        master_tries: -1
        auth_safemode: True

        # workaround https://github.com/saltstack/salt/issues/59141
        multiprocessing: False

minion_config:
  file.managed:
    - names:
      - /etc/salt/minion.d/x509.conf:
        - source: salt://etc/salt/minion.d/x509.conf
