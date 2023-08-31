salt-minion:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
{%- if not grains.get('noservices', False) %}
  service.enabled:
    - name: salt-minion
{%- endif %}

# see https://build.opensuse.org/package/view_file/openSUSE:Leap:15.1/salt/use-adler32-algorithm-to-compute-string-checksums.patch
/etc/salt/minion:
  file.replace:
    - pattern: '^(server_id_use_crc: )(.*)$'
    - repl: 'server_id_use_crc: adler32'
    - append_if_not_found: True


# speed up salt a lot, see https://github.com/saltstack/salt/issues/48773#issuecomment-443599880
speedup_minion:
  file.serialize:
    - name: /etc/salt/minion
    - serializer: yaml
    - merge_if_exists: True
    - dataset:
        disable_grains:
          - esxi
        disable_modules:
          - vsphere
        grains_cache: True

{% if 'Leap' in grains['oscodename'] %}
lock_salt_minion_pkg:
  cmd.run:
    - unless: "zypper ll | grep -q 131249"
    - name: "zypper -n in --oldpackage --allow-downgrade 'salt<=3005' && zypper al -m 'poo#131249' salt"
{%- endif %}
