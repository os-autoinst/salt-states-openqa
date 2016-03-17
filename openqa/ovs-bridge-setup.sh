#!/bin/bash
# Script to setup worker bridge for openvswitch for os-autoinst
# Based on documentation at https://github.com/os-autoinst/openQA/blob/master/docs/Networking.asciidoc
# Expects openvswitch service to be enabled and running

ovs-vsctl add-br br1
ip addr add 10.0.2.2/15 dev br1
ip route add 10.0.0.0/15 dev br1
ip link set br1 up
