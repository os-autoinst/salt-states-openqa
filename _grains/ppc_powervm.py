#!/usr/bin/env python

import subprocess

def ppc_powervm():
    return {'ppc_powervm': 'Hypervisor' in str(subprocess.check_output(args=['lscpu']))}
