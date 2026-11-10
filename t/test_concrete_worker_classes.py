#!/usr/bin/env python

import sys
from os.path import dirname

sys.path.append(dirname(__file__) + "/../_modules")

import concrete_worker_classes
import pytest


def test_compute_concrete_worker_classes():
    global_conf = {
        "WORKER_CLASS": "qemu_x86_64,qemu_x86_64_staging,tap,amd,zone-cc,size-tiny,region-prg,datacenter-dc7,location-prg2,worker33,cpu-x86_64,cpu-x86_64-v2"
    }
    workers = {
        "1-24": {
            "WORKER_CLASS": "zone-cc,region-prg,datacenter-dc7,location-prg2,worker33,cpu-x86_64,cpu-x86_64-v2"
        },
        "1-5": {
            "WORKER_CLASS+": "s390x,s390x-zVM,s390x-zVM-vswitch-l2,s390zl11,size-medium,size-small,size-tiny",
            "ZVM_PASSWORD": "lin390",
        },
        "1": {
            "WORKER_CLASS+": "osdzvm11",
            "ZVM_GUEST": "osdzvm11.oqa.prg2.suse.org",
        },
        "63": {
            "WORKER_CLASS+": "qemu_x86_64-large-mem,size-large",
        },
    }

    result = concrete_worker_classes.compute(workers, global_conf, numofworkers=63)

    # Slot 1 should have had WORKER_CLASS overridden by 1-24 (removing qemu), then appended by 1-5 and 1
    assert "qemu" not in result[1]
    assert "osdzvm11" in result[1]
    assert "s390x" in result[1]

    # Slot 63 retains global WORKER_CLASS (which has qemu) and appends WORKER_CLASS+
    assert "qemu" in result[63]
    assert "qemu_x86_64-large-mem" in result[63]

    # Keys are accessible both as int and str
    assert result[1] == result["1"]
    assert result[63] == result["63"]

    # Ranges themselves are not concrete slots
    assert "1-5" not in result
    assert "1-24" not in result


def test_compute_comma_separated_ranges():
    workers = {
        "35,36": {
            "WORKER_CLASS": "svirt-vmware",
        },
        "37-39": {
            "WORKER_CLASS+": "svirt-vmware",
        },
    }
    result = concrete_worker_classes.compute(workers, global_conf="qemu_x86_64", numofworkers=40)
    assert result[35] == "svirt-vmware"
    assert result[36] == "svirt-vmware"
    assert "qemu_x86_64,svirt-vmware" == result[37]
    assert "qemu_x86_64,svirt-vmware" == result[39]
    assert result[40] == "qemu_x86_64"
