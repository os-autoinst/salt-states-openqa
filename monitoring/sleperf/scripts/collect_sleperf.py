#!/usr/bin/env python3
"""
This script will query performance test status of current products from 
QE Performance dashboard server. The test status data will be calculated
and output total-run-times/pass-times/fail-times as the metrics of 
SLE Performance and Virtualization Performance team.
"""

import requests
import time
import math
import sys
from socket import getfqdn
from collections import OrderedDict, Counter
from requests.exceptions import ConnectTimeout, ConnectionError
from json.decoder import JSONDecodeError
from datetime import datetime

BASE_URL = "http://dashboard.qa2.suse.asia"
BASE_API_URL = f"{BASE_URL}:8889"
GITLAB_API_URL = "https://gitlab.suse.de/api/v4"
GITLAB_PROJECTS = {"SLEPerf": 6354}
hostname = getfqdn()

def to_nanos(time_stamp: float) -> float:
    return time_stamp * 1E9

def to_timestamp(source_date: str) -> float:
    "Convert date with format YYYY-mm-dd to nanosecond"
    return int(datetime.strptime(source_date, "%Y-%m-%d").timestamp() * 1E9)

def fetch_from(url):
    "Fetch json data util function"
    try:
        request = requests.get(url, timeout=30)
        data = request.json()
        return data
    except ConnectTimeout as e:
        print(f"[sleperf error] Connect Timeout to {url}", file=sys.stderr)
        raise e
    except ConnectionError as e:
        print(f"[sleperf error] Failed to establish connection to {url}", file=sys.stderr)
        raise e
    except JSONDecodeError as e:
        print(f"[sleperf error] File not found or data invalid for {url}", file=sys.stderr)
        raise e
    except Exception as e:
        print(f"[sleperf error] Exception occurred in request to {url}", file=sys.stderr)
        raise e

def fetch_product():
    "Fetch product data from QE performance dashboard server"
    url = f"{BASE_URL}/sleperf_metrics/productV2.json"
    data = fetch_from(url)
    return data

def fetch_each_category(role, release, build, arch, kernel, category, category_value):
    "Fetch test result for each category"
    url = f"{BASE_API_URL}/api/report/v3/cases/{arch}/{release}/{build}/{kernel}/{role}/{category}?category_value={category_value}"
    pass_no = 0
    fail_no = 0
    result = dict()
    data = fetch_from(url)
    cases = data['data']['cases']
    for suite_key, suite_value in cases.items():
        for case_key, case_value in suite_value.items():
            for machine_key, machine_value in case_value.items():
                for tag_key, tag_value in machine_value.items():
                    for subtag_key, subtag_value in tag_value.items():
                        fail_status = int(subtag_value['status']['Fail'])
                        if fail_status == 0:
                            pass_no += 1
                        else:
                            fail_no += 1
    result['pass'] = pass_no
    result['fail'] = fail_no
    return result

def fetch_test_status(role, product):
    "Fetch test status data from QE performance dashboard server"
    gmenu_api = f"{BASE_API_URL}/api/report/v1/utils/gmenu"
    release = product['release']
    builds = product['builds']

    gmenu_data = fetch_from(gmenu_api)
    test_data = gmenu_data['data'][role]
    write_time_prev = 0
    for build in builds:
        total_no = 0
        pass_no = 0
        fail_no = 0
        fetched_kernels = list()
        for q_product in test_data:
            q_release = q_product['q_release']
            q_build = q_product['q_build']
            q_arch = q_product['q_arch']
            q_kernel = q_product['q_kernel']
            category_list = q_product['category_list']
            if q_release == release and q_build == build and (q_kernel.endswith('-default') or q_kernel.endswith('-rt')):
                if q_kernel in fetched_kernels:
                    # Mainly for Virt-Performance, avoid re-calculate for same kernel
                    continue
                fetched_kernels.append(q_kernel)
                for category, value in category_list.items():
                    for i in value:
                        if i:
                            category_value = i
                        else:
                            category_value = "null"
                        category_result = fetch_each_category(role, q_release, q_build, q_arch, q_kernel, category, category_value)
                        pass_no += category_result['pass']
                        fail_no += category_result['fail']
        total_no = pass_no + fail_no
        if total_no > 0:
            time_stamp = int(to_nanos(time.time()))
            print(f'sle_perf_status,machine={hostname} role="{role}",milestone="{release}-{build}",total-run-times={total_no},pass-times={pass_no},fail-times={fail_no} {time_stamp}')

def fetch_gitlab_session(endpoint):
    session = requests.Session()
    current_page = 0
    try:
        # Telegraf script timeout would avoid the infinite loop if there is large data
        while True:
            url = f"{endpoint}?page={current_page}"
            current_page += 1
            data = session.get(url, timeout=30)
            for entry in data.json():
                yield entry
            if data.headers['X-Next-Page'] == '':
                break
    except ConnectionError as e:
        print(f"[sleperf error] Failed to establish connection to {url}", file=sys.stderr)
        raise e

def fetch_gitlab_commits():
    "Fetch project commits data from Gitlab"
    for prj_name, prj_id in GITLAB_PROJECTS.items():
        url = f"{GITLAB_API_URL}/projects/{prj_id}/repository/commits"
        commits = Counter()
        for entry in fetch_gitlab_session(url):
            day = entry['committed_date'][:10]
            commits[day] += 1
        for date, value in commits.items():
            print(f"{prj_name},machine={hostname} commits={value} {to_timestamp(date)}")

def print_help():
    print(f"[sleperf error] Usage: {sys.argv[0]} <TEST | COMMITS>", file=sys.stderr)
    sys.exit(0)

if len(sys.argv) != 2:
    print_help()
param = sys.argv[1]

try:
    if param == "TEST":
        product_data = fetch_product()
        for role, products in product_data.items():
            for product in products:
                fetch_test_status(role, product)
    elif param == "COMMITS":
        fetch_gitlab_commits()
    else:
        print_help()
except (ConnectTimeout, ConnectionError, JSONDecodeError) as e:
    print(e, file=sys.stderr)
