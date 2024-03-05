# Set accept_ra on all native linux bridges (non openvswitch) to allow SLAAC to work on these hosts

{% for brif in (salt['cmd.shell']('ip -brief -o link show type bridge | cut -d " " -f1').split('\n') | reject("eq", "")) %}
net.ipv6.conf.{{ brif }}.accept_ra:
  sysctl.present:
    - value: 2
{% endfor %}
