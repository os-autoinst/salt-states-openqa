#!/usr/bin/env python

mm_classes = ["tap"]
location_prefix = "location-"


def _get_worker_classes(settings):
    return settings.get("WORKER_CLASS", "").split(",")


def compute(for_host, worker_conf):
    # determine all worker classes of "for_host" host that start with "location-"
    my_conf = worker_conf.get(for_host, {})
    my_locations = _get_worker_classes(my_conf.get("global", {}))
    my_workers = my_conf.get("workers", {})
    for wnum in my_workers:
        my_locations.extend(_get_worker_classes(my_workers[wnum]))
    my_locations = filter(
        lambda worker_class: worker_class.startswith(location_prefix), my_locations
    )

    # define set of worker classes another host must have to be connected over GRE tunnel(s)
    peer_classes = mm_classes.copy()
    peer_classes.extend(my_locations)

    # return a list of all hosts that have the required classes
    peers = []
    for host in worker_conf:
        host_conf = worker_conf[host]
        if not isinstance(host_conf, dict):
            continue
        host_workers = host_conf.get("workers", {})
        worker_classes = _get_worker_classes(host_conf.get("global", {}))
        for wnum in host_workers.keys():
            worker_classes.extend(_get_worker_classes(host_workers[wnum]))
        if all(worker_class in worker_classes for worker_class in peer_classes):
            peers.append(host)
    return peers
