## Description

This repository contains documentation and scripts used to configure monitoring services for openQA servers both on the [thruk and nagios instances maintaned by SUSE Infra] (infra-nrpe-mk-monitoring.md) and on a grafana/graphite [proof-of-concept] (http://10.86.0.11:3000/).

**Important**: this is a work in progress.

### Metrics collection

Metrics are being collected via a [shell script] (get-metrics) and sent to a graphite instance via NetCat.

### Graphite configuration

The current proof-of-concept uses a graphite docker container as the metric collection service and data source for grafana.

To this end, the [graphiteapp/graphite-statsd] (https://hub.docker.com/r/graphiteapp/graphite-statsd/) docker image is being used, mostly with a plain configuration.

The docker container is being created/run with the following command:

```
docker run -d --name graphite --restart=always -p 80:80 -p 2003:2003 -p 2004:2004 -p 2023:2023 -p 2024:2024 -p 8125:8152/udp -p 8126:8126 graphiteapp/graphite-statsd
```

The default retention policy for metrics in the default configuration of the graphite image is 6 hours, so before receiving any new metric, it is recommended to go into the container and change this value in the files `/etc/graphite-statsd/conf/opt/graphite/conf/storage-schemas.conf` and `/opt/graphite/conf/storage-schemas.conf`.

The retention policy is stored in whisper files maintained by graphite, and it is possible to change them using the script `whisper-resize.py`. For example:

```
docker exec -it graphite bash
find /opt/graphite/storage/whisper/openqaworker3/ -type f -print | while read i; do whisper-resize.py $i 10s:12h 1m:6d 10m:1800d; done
```

Will change the retention policy to 12 hours for all existing metrics.

### Grafana configuration

Similarly, the grafana front end is currently provided also with a [docker image] (https://hub.docker.com/r/grafana/grafana/).

It has been configured with a separate volume, to allow persistence of the configuration outside of the container itself.

```
docker volume create grafana-storage
docker run -d -p 3000:3000 --name=grafana --restart=always -v grafana-storage:/var/lib/grafana grafana/grafana
```

If using older versions of the grafana docker image, instead of a docker volume, the persistent data was saved on a volume from a busybox image:

```
docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest
docker run -d -p 3000:3000 --name=grafana --restart=always --volumes-from grafana-storage grafana/grafana
```
