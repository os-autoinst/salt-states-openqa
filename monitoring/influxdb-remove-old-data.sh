#!/bin/bash -e

measurements=(nginx_log cpu apache_log procstat disk ping net mem diskio chrony system)
age="${age:-"180d"}"

for measurement in "${measurements[@]}"; do
        influx -database telegraf -execute "DELETE FROM $measurement WHERE time < now() - $age;"
done
