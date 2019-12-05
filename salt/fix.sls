# See https://progress.opensuse.org/issues/54458
# and https://github.com/aplanas/salt/commit/0315a25cf38a4c001008a3e68917b4611e368197
{%- if grains.osrelease < '15.2' %}
patch:
  pkg.installed:
    - refresh: False

{% set pythonversion = grains['pythonversion'][0:2]|join('.') %}
# in never versions of salt file.patch unfortunately triggers ugly error
# messages in the minion log, see https://github.com/saltstack/salt/issues/52329
/usr/lib/python{{ pythonversion }}/site-packages/salt/modules/file.py:
  file.patch:
    - source: salt://salt/gh_saltstack_salt_52329_error_reverse_patch_output.patch

# apply only for non-x86_64 which have an older versions of python3-salt
  {% if 'aarch64' in grains['cpuarch'] or 'ppc64le' in grains['cpuarch'] %}
/usr/lib/python{{ pythonversion }}/site-packages/salt/grains/core.py:
  file.patch:
    - source: salt://salt/ignore_host_not_found.patch
    - strip: 1
  {% endif %}
{%- endif %}
