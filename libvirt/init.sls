libvirt.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - cronie
      - libvirt
      {% if grains['osarch'] == 's390x' %}
      - multipath-tools
      {% endif %}

{%- if grains.get('openqa_share_nfs', False) or grains.get('roles', '') in ['worker'] %}
include:
 - openqa.nfs_share
{% endif %}

/usr/local/bin/cleanup-openqa-assets:
  file.managed:
    - source: salt://libvirt/cleanup-openqa-assets
{%- if not grains.get('noservices', False) %}
  cron.present:
    - user: root
    - minute: '*/10'
{%- endif %}

{% if grains['osarch'] == 's390x' %}
/etc/modules-load.d/kvm.conf:
  file.managed:
    - contents:
      - 'options kvm nested=1'
{% endif %}
