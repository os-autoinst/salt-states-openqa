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
{% for pkg_name in ['salt', 'salt-bash-completion', 'salt-minion'] %}
lock_{{ pkg_name }}_pkg:
  cmd.run:
    - unless: 'zypper ll | grep -qE "{{ pkg_name }}.*\| poo#131249"'
    - name: "(zypper -n in --oldpackage --allow-downgrade '{{ pkg_name }}<=3005' || zypper -n in --oldpackage --allow-downgrade '{{ pkg_name }}<=3005.1') && zypper al -m 'poo#131249 - potential salt regression, unresponsive salt-minion' {{ pkg_name }}"

{% set unlocked_conflicting_patches = salt['cmd.shell']('zypper se --conflicts-pkg salt-minion | grep -P \'^!\s.*?\|\' | cut -d "|" -f 2 | awk \'{$1=$1;print}\'').split("\n") %}
{% if unlocked_conflicting_patches[0] != "" %}
{% for conflicting_patch in unlocked_conflicting_patches %}
lock_{{ conflicting_patch }}_for_{{ pkg_name }}_patch:
  cmd.run:
    - unless: 'zypper ll | grep -qE "{{ conflicting_patch }}"'
    - name: "zypper al -m 'poo#131249 - patch would conflict with {{ pkg_name }}' -t patch {{ conflicting_patch }}"
{% endfor %}
{% endif %}
{% endfor %}
{%- endif %}
