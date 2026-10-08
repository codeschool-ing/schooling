#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The API the lesson calls is devapi, the lab's REST API on each router,
# written for this course and printed in full in the-server.md, whence
# lab.sh extracts it. It answers from FRR
# and the kernel and applies every change as a vtysh command.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, including ~/.netops-password and
# ~/.audit-password on ctl; and the files ana wrote (put below), whose
# contents the lesson shows. Dates and tokens differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine, and what it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
# put PATH: a file ana wrote on ctl, from stdin. Its content is shown in the lesson.
put() { lab exec ctl ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
# typed ROUTER 'line' ...: an interactive SSH session from ctl to a router's CLI,
# each line typed at the prompt, and the terminal as it looked afterwards.
typed() {
  local h=$1; shift
  printf 'ana@ctl:~$ ssh netops@%s\n' "$h"
  local script='sleep 1.2;' l
  for l in "$@"; do script+=" printf '%s\\n' '$l'; sleep 0.5;"; done
  lab exec ctl ana "( $script ) | ssh -tt netops@$h 2>&1 | tr -d '\\r'" || true
}
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while others are typed, the way a
# second terminal would be: its prompt and output are printed when it ends.
bgon() {
  printf 'ana@%s:~$ %s\n' "$1" "$2" > /tmp/bg.out
  lab exec "$1" ana "$2" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep "${3:-1.5}"
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab reset

block no-token
on ctl 'curl -si --cacert lab-ca.pem https://edge1.example.net/api/v1/system'
block login
on ctl 'jq -n --arg p "$(cat .netops-password)" '"'"'{username: "netops", password: $p}'"'"' > login.json'
on ctl 'curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login'
block with-token
on ctl 'curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .token'
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/system'
block wrong-password
on ctl 'curl -si --cacert lab-ca.pem -H "Content-Type: application/json" -d '"'"'{"username": "netops", "password": "guess"}'"'"' https://edge1.example.net/api/v1/auth/login'
block read-only
on ctl 'jq -n --arg p "$(cat .audit-password)" '"'"'{username: "audit", password: $p}'"'"' > audit.json'
on ctl 'curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @audit.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .audit-token'
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .audit-token)" https://edge1.example.net/api/v1/interfaces/eth2'
on ctl 'curl -si --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .audit-token)" -H "Content-Type: application/json" -d '"'"'{"description": "branch 1 LAN"}'"'"' https://edge1.example.net/api/v1/interfaces/eth2'

put login.py <<'CODE'
from pathlib import Path

import requests

BASE = "https://edge1.example.net/api/v1"
CA = "lab-ca.pem"
password = Path("~/.netops-password").expanduser().read_text().strip()

r = requests.post(f"{BASE}/auth/login", json={"username": "netops", "password": password},
                  verify=CA, timeout=10)
r.raise_for_status()
token = r.json()["token"]

r = requests.get(f"{BASE}/system", headers={"Authorization": f"Bearer {token}"},
                 verify=CA, timeout=10)
r.raise_for_status()
print(r.json())
CODE
block login-py
on ctl 'python login.py'

block post
on ctl 'curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '"'"'{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}'"'"' https://edge1.example.net/api/v1/static-routes'
block post-again
on ctl 'curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '"'"'{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}'"'"' https://edge1.example.net/api/v1/static-routes'
block on-the-router
on ctl 'ssh netops@edge1 "show running-config" | grep "ip route"'
block patch
on ctl 'curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '"'"'{"description": "branch 1 LAN"}'"'"' https://edge1.example.net/api/v1/interfaces/eth2'
block delete
on ctl 'curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25'
on ctl 'curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25'
block invalid
on ctl 'curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '"'"'{"prefix": "192.0.2.130/25", "next_hop": "198.51.100.1"}'"'"' https://edge1.example.net/api/v1/static-routes'
block method
on ctl 'curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/interfaces/eth2'

put devapi.py <<'CODE'
import time
from pathlib import Path

import requests


class Device:
    def __init__(self, host, username="netops", password_file="~/.netops-password"):
        self.base = f"https://{host}.example.net/api/v1"
        self.http = requests.Session()
        self.http.verify = "lab-ca.pem"
        password = Path(password_file).expanduser().read_text().strip()
        r = self.http.post(f"{self.base}/auth/login", timeout=10,
                           json={"username": username, "password": password})
        r.raise_for_status()
        self.http.headers["Authorization"] = "Bearer " + r.json()["token"]

    def request(self, method, path, **kwargs):
        url = path if path.startswith("https://") else self.base + path
        for attempt in range(4):
            r = self.http.request(method, url, timeout=10, **kwargs)
            if r.status_code != 429 or attempt == 3:
                break
            wait = int(r.headers.get("Retry-After", "1"))
            print(f"  429 on {path}: waiting {wait} s")
            time.sleep(wait)
        r.raise_for_status()
        return r.json() if r.content else None

    def all(self, path, **params):
        page = self.request("GET", path, params=params)
        while True:
            yield from page["results"]
            if not page["next"]:
                return
            page = self.request("GET", page["next"])
CODE
put static.py <<'CODE'
import sys

from devapi import Device

WANT = {"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1", "distance": 10}
path = "/static-routes/" + WANT["prefix"].replace("/", "%2F")

edge1 = Device(sys.argv[1] if len(sys.argv) > 1 else "edge1")
current = next((r for r in edge1.all("/static-routes") if r["prefix"] == WANT["prefix"]), None)
if current == WANT:
    print(f"{WANT['prefix']}: already as intended")
else:
    edge1.request("PUT", path, json=WANT)
    print(f"{WANT['prefix']}: {'created' if current is None else 'updated'}")
CODE
block static-py
on ctl 'python static.py'
on ctl 'python static.py'

block page-curl
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" "https://edge1.example.net/api/v1/interfaces?limit=2"'
put routes.py <<'CODE'
from devapi import Device

edge1 = Device("edge1")
for route in edge1.all("/routes", limit=3):
    hops = ", ".join(h.get("ip") or h["interface"] for h in route["next_hops"])
    mark = ">" if route["selected"] else " "
    print(f"{mark} {route['prefix']:<18} {route['protocol']:<10} via {hops}")
CODE
block routes-py
on ctl 'python routes.py'

put burst.py <<'CODE'
from devapi import Device

core1 = Device("core1")
for i in range(40):
    core1.request("GET", "/system")
print("40 requests answered")
CODE
block burst
on ctl 'time python burst.py'

block no-ca
on ctl 'curl -sS https://edge1.example.net/api/v1/system; echo "exit status $?"'
on ctl 'python -c "import requests; requests.get('"'"'https://edge1.example.net/api/v1/system'"'"')" 2>&1 | tail -1'
block cert
on ctl 'openssl s_client -connect edge1.example.net:443 -CAfile lab-ca.pem </dev/null 2>/dev/null | grep -E "^subject=|^issuer=|^Verify return code"'
