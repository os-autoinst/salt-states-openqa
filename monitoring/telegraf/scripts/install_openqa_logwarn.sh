#!/bin/bash
set -e
curl https://raw.githubusercontent.com/os-autoinst/openqa-logwarn/master/logwarn_openqa > /usr/bin/logwarn_openqa
chmod a+x /usr/bin/logwarn_openqa