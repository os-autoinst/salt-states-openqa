#!/usr/bin/env python
#
# If you need to debug this module you can fetch some example data with e.g.:
# `ssh root@openqa.suse.de -- salt mania.qe.nue2.suse.org pillar.get workerconf --out=json > /tmp/workerconf.json`
# And load this json into the compute function to debug what it would output:
# ```
# import json
# from gre_peers import compute
# with open("/tmp/workerconf.json", "r") as fd:
#     data = fd.read()
# wdata = json.loads(data)
# compute("mania", wdata["mania.qe.nue2.suse.org"])
# ```
#

mm_classes = {"tap"}
location_prefix = "location-"


def _get_worker_classes(settings):
    return set(settings.get("WORKER_CLASS", "").split(","))


def compute(for_host, worker_conf):
    # determine all worker classes of "for_host" host that start with "location-"
    my_conf = worker_conf.get(for_host, {})
    my_locations = _get_worker_classes(my_conf.get("global", {}))
    my_workers = my_conf.get("workers", {})
    for my_worker in my_workers.values():
        my_locations.update(_get_worker_classes(my_worker))
    my_locations = {worker_class for worker_class in my_locations if worker_class.startswith(location_prefix)}

    # define set of worker classes another host must have to be connected over GRE tunnel(s)
    peer_classes = mm_classes.copy()
    peer_classes.update(my_locations)

    # return a list of all hosts that have the required classes
    peers = []
    for host, host_conf in worker_conf.items():
        if not isinstance(host_conf, dict):
            continue
        host_workers = host_conf.get("workers", {})
        worker_classes = _get_worker_classes(host_conf.get("global", {}))
        for host_worker in host_workers.values():
            worker_classes.update(_get_worker_classes(host_worker))
        if peer_classes.issubset(worker_classes):
            peers.append(host)
    return peers
