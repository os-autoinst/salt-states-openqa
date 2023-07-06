#!/usr/bin/env python3

from datetime import datetime
# counter class is like a dictionary specialized in keeping count of keys
from collections import Counter
from socket import getfqdn
import requests


PROJECTS = {'Project_C': 6967, 'Project_K': 6976,
            'Project_M': 6959, 'Project_P': 6958}

BASE_API_URL = "https://gitlab.suse.de/api/v4"


def to_timestamp(source_date: str) -> float:
    "converts a date in format 2022-04-25 to unix nanosecond timestamp required by influxdb"
    return int(datetime.strptime(source_date, "%Y-%m-%d").timestamp()*1E9)


# where are we running ?
hostname = getfqdn()

# try to reuse http session
session = requests.Session()
for pj_name, pj_id in PROJECTS.items():
    current_page = 0
    commits = Counter()
    while True:
        current_page += 1
        url = f"{BASE_API_URL}/projects/{pj_id}/repository/commits?page={current_page}"
        data = session.get(url, timeout=30)
        for entry in data.json():
            day = entry['committed_date'][:10]
            commits[day] += 1
        # loop until header 'X-Next-Page' is empty
        # telegraf has script timeout, so we don't risk infinite loop
        if data.headers['X-Next-Page'] == '':
            break
    # once all pages has been collected, print the data
    for date, value in commits.items():
        print(f"{pj_name},machine={hostname} commits={value} {to_timestamp(date)}")
