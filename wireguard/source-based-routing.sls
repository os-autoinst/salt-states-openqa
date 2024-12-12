source-based-routing.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - jq

/etc/iproute2/rt_tables:
  file.append:
    - text: '240     nowg'

/usr/local/bin/configure-source-based-routing:
  file.managed:
    - mode: "0755"
    - source: salt://wireguard/configure-source-based-routing
    - makedirs: true

/etc/systemd/system/configure-source-based-routing@.service:
  file.managed:
    - create: true
    - contents: |
        [Unit]
        Description=Wicked hook service to configure source based routing for %i

        [Service]
        Type=oneshot
        ExecStart=/usr/local/bin/configure-source-based-routing %i

{%- if not grains.get('noservices', False) %}
configure-source-based-routing service reload:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: /etc/systemd/system/configure-source-based-routing@.service
{% endif %}

# PROTO needs to be set correctly otherwise the POST_UP_SCRIPT/unit
# will not get executed. On hosts with wireguard we know that we have
# DHCP for IPv4 and SLAAC for IPv6.
/etc/sysconfig/network/ifcfg-{{ grains["default_interface"] }}:
  file.keyvalue:
    - append_if_not_found: True
    - separator: '='
    - key_values:
        BOOTPROTO: "'dhcp4+auto6'"
        POST_UP_SCRIPT: "'systemd:configure-source-based-routing@.service'"
