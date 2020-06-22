#!/usr/bin/env python

from subprocess import check_output


def ppc_powervm():
    return {'ppc_powervm': 'Hypervisor' in str(check_output('lscpu'))}


if __name__ == '__main__':
    grains = ppc_powervm()
    print("grains: %s" % grains)
