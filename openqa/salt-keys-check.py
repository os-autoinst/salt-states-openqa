#!/usr/bin/python3

import os
import sys
import json
import subprocess
import socket

script_path = os.path.abspath(sys.argv[0])
host = socket.gethostbyaddr(socket.gethostname())[0]

js = subprocess.check_output(["salt-key", "--out=json"])
j = json.loads(js)

bad = {
    "unaccepted": j["minions_pre"],
    "rejected": j["minions_rejected"],
    "denied": j["minions_denied"],
}

# dict of hostname -> ticket entries for all hosts with salt-keys in a state different from "accepted"
MINION_KEYS_NOT_ACCEPTED_REASONS = json.load(open('/etc/salt-keys-check-keys-not_accepted_reasons.json'))

exit_code = 0
for status, hostnames in bad.items():
    for hostname in hostnames:
        if not hostname in MINION_KEYS_NOT_ACCEPTED_REASONS:
            print(f"salt-key for {hostname} is {status} with no reason listed in {host}:{script_path}")
            exit_code = 1
sys.exit(exit_code)
