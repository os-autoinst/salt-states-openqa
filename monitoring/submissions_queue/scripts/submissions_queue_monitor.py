#!/usr/bin/env python3

import json
import requests

response = requests.get('https://smelt.suse.de/api/v1/overview/submission_ready/?format=json')
data = json.loads(response.text)
print("submission_queue,machine=openqa-monitor.qa.suse.de submissions=%di" % data['count'])
