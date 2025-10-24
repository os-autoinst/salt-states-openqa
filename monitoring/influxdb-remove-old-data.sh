#!/bin/bash -e

age="${age:-"180d"}"
age_nginx_log="${age_nginx_log:-"20d"}"
influx -database telegraf -execute "DELETE FROM nginx_log WHERE time < now() - $age_nginx_log;"
measurements=(cpu apache_log procstat disk ping net mem diskio chrony system)
for measurement in "${measurements[@]}"; do
        influx -database telegraf -execute "DELETE FROM $measurement WHERE time < now() - $age;"
done
