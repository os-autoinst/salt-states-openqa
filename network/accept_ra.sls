# Set accept_ra on all native linux bridges (non openvswitch) to allow SLAAC to work on these hosts

{% for brif in (salt['cmd.shell']('ip -brief -o link show type bridge | cut -d " " -f1').split('\n') | reject("eq", "")) %}
net.ipv6.conf.{{ brif }}.accept_ra:
  sysctl.present:
    - value: 2
{% endfor %}

{% if 'external_openqa_hypervisor' in grains.get('roles', []) or 'libvirt' in grains.get('roles', []) %}
# Disable kernel RA processing globally on hypervisors to prevent macvtap interfaces
# from hijacking the default IPv6 route via SLAAC. NetworkManager/Wicked will still
# correctly configure RAs for the primary managed interfaces.
net.ipv6.conf.all.accept_ra:
  sysctl.present:
    - value: 0

net.ipv6.conf.default.accept_ra:
  sysctl.present:
    - value: 0
{% endif %}
