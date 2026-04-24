#!/usr/bin/python3

import os
import sys
import json
import subprocess
import socket
import requests

script_path = os.path.abspath(sys.argv[0])

js = subprocess.check_output(["salt-key", "--out=json"])
j = json.loads(js)

states = {
    "unaccepted": j["minions_pre"],
    "rejected": j["minions_rejected"],
    "denied": j["minions_denied"],
}

backlog = requests.get("https://progress.opensuse.org/issues.json?query_id=757").json()

def get_ticket(minion):
    for issue in backlog["issues"]:
        hostname = minion.split(".", 1)[0]
        if any(match in issue["subject"] for match in [minion, hostname]):
            return f"https://progress.opensuse.org/issues/{issue['id']}"

if states["rejected"]:
    print("Minions with rejected keys (this is okay):")
    for minion in states["rejected"]:
        print(f"  {minion}")

exit_code = 0
if states["denied"]:
    print("\nDenied keys:")
    for minion in states["denied"]:
        ticket = get_ticket(minion)
        print(f"  {minion} (Ticket: {ticket})")
        if not ticket:
            exit_code = 1

if states["unaccepted"]:
    print("\nUnaccepted keys:")
    for minion in states["unaccepted"]:
        ticket = get_ticket(minion)
        print(f"  {minion} (Ticket: {ticket})")
        if not ticket:
            exit_code = 1

if exit_code:
    print("\nThere are minions with unaccepted/denied keys and no ticket mentioning them!")

sys.exit(exit_code)
