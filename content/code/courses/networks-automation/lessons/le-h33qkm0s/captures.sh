#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The sender is devapi on edge1, the lab's router API, whose webhooks are
# signed with HMAC-SHA256 and retried at 1, 2 and 4 seconds when a delivery is
# not answered with a 2xx. The service desk is deskd, on tickets. Both were
# written for this course; deskd is printed in full in the-desk.md and devapi
# in lesson 2.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, and the files ana wrote (put below), whose
# contents the lesson shows. Times, delivery ids
# and signatures differ on every run.
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
on ctl 'head -c 24 /dev/urandom | base64 > ~/.hook-secret; chmod 600 ~/.hook-secret'
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
put desk.py <<'CODE'
from pathlib import Path

import requests

DESK = "https://tickets.example.net/api/tickets"
http = requests.Session()
http.verify = "lab-ca.pem"
http.headers["Authorization"] = "Token " + Path("~/.desk-token").expanduser().read_text().strip()


def request(method, url, **kwargs):
    r = http.request(method, url, timeout=10, **kwargs)
    r.raise_for_status()
    return r.json()


def handle(event):
    title = f"{event['device']} {event['interface']} is down"
    found = request("GET", DESK, params={"status": "open", "q": title})["results"]
    if event["event"] == "interface.down":
        if found:
            t = request("POST", f"{DESK}/{found[0]['number']}/comments",
                        json={"body": f"down again at {event['time']}"})
            return f"{t['number']}: commented, down again"
        t = request("POST", DESK, json={"title": title, "priority": "high", "requester": "edge-monitor",
                                        "body": f"{event['description'] or 'no description'}, down at {event['time']}"})
        return f"{t['number']}: opened"
    if found:
        number = found[0]["number"]
        request("POST", f"{DESK}/{number}/comments", json={"body": f"up at {event['time']}"})
        t = request("PATCH", f"{DESK}/{number}", json={"status": "resolved"})
        return f"{t['number']}: resolved"
    return "up, and no open ticket to resolve"
CODE
put subscribe.py <<'CODE'
import sys
from pathlib import Path

from devapi import Device

secret = Path("~/.hook-secret").expanduser().read_text().strip()
edge1 = Device("edge1")
hook = edge1.request("POST", "/webhooks", json={
    "url": "http://192.0.2.10:8080/hook",
    "events": ["interface.down", "interface.up"],
    "secret": secret})
print(hook)
CODE
put hook_print.py <<'CODE'
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class Hook(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        print("headers:", {k: v for k, v in self.headers.items() if k.startswith("X-Devapi")})
        print("body:   ", json.loads(body))
        self.send_response(204)
        self.end_headers()

    def log_message(self, *args):
        pass


HTTPServer(("192.0.2.10", 8080), Hook).handle_request()
CODE
put receiver.py <<'CODE'
import hashlib
import hmac
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import desk

SECRET = Path("~/.hook-secret").expanduser().read_text().strip().encode()
SEEN = set()
FAIL_ONCE = "--fail-once" in sys.argv


def signed(body, header):
    want = "sha256=" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(want, header or "")


class Hook(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        delivery = self.headers.get("X-Devapi-Delivery")
        if not signed(body, self.headers.get("X-Devapi-Signature")):
            print(f"{delivery}: bad signature, refused")
            return self.answer(401)
        if delivery in SEEN:
            print(f"{delivery}: already handled, ignored")
            return self.answer(204)
        event = json.loads(body)
        print(f"{delivery}: {event['event']} {event['device']} {event['interface']}")
        print("  ", desk.handle(event))
        SEEN.add(delivery)
        if FAIL_ONCE and len(SEEN) == 1:
            print(f"{delivery}: answering 500 on purpose")
            return self.answer(500)
        self.answer(204)

    def answer(self, status):
        self.send_response(status)
        self.end_headers()

    def log_message(self, *args):
        pass


server = HTTPServer(("192.0.2.10", 8080), Hook)
for _ in range(int(sys.argv[1])):
    server.handle_request()
CODE
put link.py <<'CODE'
import sys

from devapi import Device

router, interface, state = sys.argv[1:4]
Device(router).request("PATCH", f"/interfaces/{interface}", json={"enabled": state == "up"})
print(f"{router} {interface}: {state}")
CODE
put deliveries.py <<'CODE'
from devapi import Device

edge1 = Device("edge1")
hook = edge1.request("GET", "/webhooks")["results"][0]
for d in edge1.all(f"/webhooks/{hook['id']}/deliveries"):
    print(d["delivery"], "attempt", d["attempt"], "at", d["time"][11:19], "->", d["status"])
CODE

block subscribe
on ctl 'python subscribe.py'

block first-event-down
bgon ctl 'python hook_print.py' 2
on ctl 'python link.py edge1 eth2 down'
block first-event
fgon

block nobody-listening
on ctl 'python link.py edge1 eth2 up'
sleep 9
on ctl 'python deliveries.py'

block forged
bgon ctl 'python receiver.py 1' 2
on ctl 'curl -s -o /dev/null -w "%{http_code}\n" -H "Content-Type: application/json" -H "X-Devapi-Delivery: forged-1" -H "X-Devapi-Signature: sha256=0000" -d '"'"'{"event": "interface.up", "device": "edge1", "interface": "eth1"}'"'"' http://192.0.2.10:8080/hook'
block forged-receiver
fgon

block ticket-down
bgon ctl 'python receiver.py 1' 2
on ctl 'python link.py edge1 eth2 down'
block ticket-down-receiver
fgon
block ticket-open
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" "https://tickets.example.net/api/tickets?status=open"'

block retry-up
bgon ctl 'python receiver.py 2 --fail-once' 2
on ctl 'python link.py edge1 eth2 up'
block retry-up-receiver
fgon
block retry-deliveries
on ctl 'python deliveries.py | tail -2'
block ticket-resolved
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" https://tickets.example.net/api/tickets/INC-1001'
