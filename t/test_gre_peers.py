#!/usr/bin/env python

import sys
from os.path import dirname

sys.path.append(dirname(__file__) + "/../_modules")

import gre_peers
import pytest


def test_compute():
    workerconf = {
        "required_external_networks": [],
        "foo": {
            "global": {"WORKER_CLASS": "foo,tap,location-site1"},
        },
        "bar": {
            "workers": {"1": {"WORKER_CLASS": "bar,tap,location-site2"}},
        },
        "baz": {
            "global": {"WORKER_CLASS": "baz,tap"},
            "workers": {"1": {"WORKER_CLASS": "location-site1"}},
        },
        "bay": {
            "global": {"WORKER_CLASS": "bay"},
            "workers": {"1": {"WORKER_CLASS": "location-site1"}},
        },
    }

    assert gre_peers.compute("foo", workerconf) == [
        "foo",
        "baz",
    ], "foo grouped with baz"
    assert gre_peers.compute("baz", workerconf) == [
        "foo",
        "baz",
    ], "baz grouped with foo"
    assert gre_peers.compute("bar", workerconf) == [
        "bar"
    ], "bar not grouped with other hosts"
