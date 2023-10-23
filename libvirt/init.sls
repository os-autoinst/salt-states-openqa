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

include:
 - openqa.nfs_share

/usr/local/bin/cleanup-openqa-assets:
  file.managed:
    - source: salt://libvirt/cleanup-openqa-assets
  cron.present:
    - user: root
    - minute: 0
    - hour: '*/1'

{% if grains['osarch'] == 's390x' %}
/etc/modules-load.d/kvm.conf:
  file.managed:
    - contents:
      - 'options kvm nested=1'
{% endif %}
