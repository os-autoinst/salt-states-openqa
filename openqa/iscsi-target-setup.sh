#!/bin/bash
# Script to setup worker target for openqa
# Expects tgt to be enabled and running
# Expects /opt/openqa-iscsi-disk to exist
# This file is generated by salt - don't touch
# Hosted on https://gitlab.suse.de/openqa/salt-states-openqa

tgtadm --lld iscsi --mode target --op new --tid=1 --targetname iqn.2016-02.openqa.de:for.openqa
tgtadm --lld iscsi --mode logicalunit --op new --tid 1 --lun 1 -b /opt/openqa-iscsi-disk
tgtadm --lld iscsi --mode target --op bind --tid 1 -I ALL
tgt-admin --dump|grep -v default-driver >/etc/tgt/conf.d/openqa-scsi-target.conf

