#!/usr/bin/env python3

from datetime import datetime
# counter class is like a dictionary specialized in keeping count of keys
from collections import Counter, defaultdict
from socket import getfqdn
import sys
from dataclasses import dataclass
from typing import Optional
import requests


PROJECTS = {'Project_C': 6967, 'Project_K': 6976,
            'Project_M': 6959, 'Project_P': 6958,
            'HANAPERF_CI': 6968}

BASE_API_URL = "https://gitlab.suse.de/api/v4"


def to_timestamp(source_date: str) -> float:
    "converts a date in format 2022-04-25 to unix nanosecond timestamp required by influxdb"
    return int(datetime.strptime(source_date, "%Y-%m-%d").timestamp()*1E9)


def to_datetime(s: str) -> datetime:
    "convert a string in format 2022-04-25 in a datetime object"
    ymd = [int(x) for x in s.split('-')]
    return datetime(ymd[0], ymd[1], ymd[2])


def date_difference(a: str, b: str = '') -> int:
    "calc days between two dates A and B in format 2022-04-25. B can be empty string"
    if b:
        return (to_datetime(b)-to_datetime(a)).days
    return (datetime.now()-to_datetime(a)).days


# where are we running ?
hostname = getfqdn()


def fetch_data_from(endpoint):
    "iterator/generator that returns chunks of json data from a REST endpoint"
    session = requests.Session()  # try to reuse http session
    current_page = 0
    while True:  # we don't risk infinite loop since telegraf has script timeout
        current_page += 1
        url = endpoint + f"?page={current_page}"
        data = session.get(url, timeout=30)
        for entry in data.json():
            yield entry
        if data.headers['X-Next-Page'] == '':
            break


def get_commits():
    "output data about commits"
    for pj_name, pj_id in PROJECTS.items():
        url = f"{BASE_API_URL}/projects/{pj_id}/repository/commits"
        commits = Counter()
        for entry in fetch_data_from(url):
            day = entry['committed_date'][:10]
            commits[day] += 1
        # once all pages has been collected, print the data
        for date, value in commits.items():
            print(f"{pj_name},machine={hostname} commits={value} {to_timestamp(date)}")


@dataclass
class Issue:
    opened_at: str
    closed_at: Optional[str] = None
    duration: Optional[int] = 0


def get_issues():
    "output data about issues"
    for pj_name, pj_id in PROJECTS.items():
        issues = []
        url = f"{BASE_API_URL}/projects/{pj_id}/issues"
        for entry in fetch_data_from(url):
            created_day = entry['created_at']
            closed_day = entry['closed_at']
            issue = Issue(created_day[:10])
            if closed_day:
                issue.closed_at = closed_day[:10]
                issue.duration = date_difference(issue.opened_at, issue.closed_at)
            else:
                issue.duration = date_difference(issue.opened_at)
            issues.append(issue)
        # count open and closed issue for each date
        issues_by_date = defaultdict(Counter)
        duration_by_date = Counter()
        for i in issues:
            issues_by_date[i.opened_at][0] += 1
            duration_by_date[i.opened_at] += i.duration
            if i.closed_at:
                issues_by_date[i.closed_at][1] += 1
        for date, value in issues_by_date.items():
            print(f"{pj_name},machine={hostname} opened_issues={value[0]},closed_issues={value[1]} {to_timestamp(date)}")
        # for closed issues, output average duration in days
        for date, summed_duration in duration_by_date.items():
            avg = summed_duration // issues_by_date[date][0]  # divide total by number of opened issues in that day
            print(f"{pj_name},machine={hostname} issue_age={avg} {to_timestamp(date)}")


def print_help():
    print(f"Usage: {sys.argv[0]} <COMMITS | ISSUES>")
    sys.exit(1)

if len(sys.argv) != 2:
    print_help()

command = sys.argv[1].upper()

if command == "COMMITS":
    get_commits()
elif command == "ISSUES":
    get_issues()
else:
    print_help()
