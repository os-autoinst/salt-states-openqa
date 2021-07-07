#!/usr/bin/env python

# use salt.utils.network directly (instead of salt.modules.network) to workaround
# https://github.com/saltstack/salt/issues/58860 and https://progress.opensuse.org/issues/94994
import salt.utils.network

def ip_addrs(interface=None, include_loopback=False, cidr=None, type=None):
    """
    Returns a list of IPv4 addresses assigned to the host. 127.0.0.1 is
    ignored, unless 'include_loopback=True' is indicated. If 'interface' is
    provided, then only IP addresses from that interface will be returned.
    Providing a CIDR via 'cidr="10.0.0.0/8"' will return only the addresses
    which are within that subnet. If 'type' is 'public', then only public
    addresses will be returned. Ditto for 'type'='private'.

    .. versionchanged:: 3001
        ``interface`` can now be a single interface name or a list of
        interfaces. Globbing is also supported.

    CLI Example:

    .. code-block:: bash

        salt '*' network.ip_addrs

    This function is taken from salt.modules.network and has been adjusted
    for not relying on `__utils__` (see issues referenced by comment on
    top).
    """
    addrs = salt.utils.network.ip_addrs(interface=interface, include_loopback=include_loopback)
    if cidr:
        return [i for i in addrs if salt.utils.network.in_subnet(cidr, [i])]
    else:
        if type == "public":
            return [i for i in addrs if not is_private(i)]
        elif type == "private":
            return [i for i in addrs if is_private(i)]
        else:
            return addrs

def default_interface():
    """Return the default network interface name from a machine based on its IPv4 configuration."""
    grains = {'default_interface': None}
    # Use first IP which matches the SUSE internal network
    try:
        internalip = ip_addrs(cidr='10.160.0.0/13')[0]
    except IndexError:
        return grains
    interfaces = salt.utils.network.interfaces()

    # Iterate over all interfaces and see which one contains the IP from above first
    for interface, data in interfaces.items():
        ips = [ip_data.get('address') for ip_data in data.get('inet', {})]
        if internalip in ips:
            grains['default_interface'] = interface
            break

    return grains
