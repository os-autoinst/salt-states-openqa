#!/usr/bin/env python
import salt.modules.network


def default_interface():
    """Return the default network interface name from a machine based on its IPv4 configuration."""
    grains = {'default_interface': None}
    # Use first IP which matches the SUSE internal network
    try:
        internalip = salt.modules.network.ip_addrs(cidr='10.160.0.0/13')[0]
    except IndexError:
        return grains
    interfaces = salt.modules.network.interfaces()

    # Iterate over all interfaces and see which one contains the IP from above first
    for interface, data in interfaces.items():
        ips = [ip_data.get('address') for ip_data in data.get('inet', {})]
        if internalip in ips:
            grains['default_interface'] = interface
            break

    return grains
