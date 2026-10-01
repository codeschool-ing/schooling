#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The gNMI target on each router is devapi, written for this course and printed
# in full in lab.sh: the gNMI 0.8 service over TLS on port 9339, serving a
# subset of openconfig-interfaces and openconfig-system from FRR and from the
# kernel's counters. The clients are real: gnmic v0.42.0 and pygnmi 0.8.15.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; and the files ana wrote (put below), whose
# contents the lesson shows. Traffic in the rate section is a ping from pc1 to
# pc2, shown as a second terminal. Counters, timestamps and rates differ on
# every run.
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

put .gnmic.yaml <<'CODE'
username: netops
tls-ca: lab-ca.pem
encoding: json_ietf
CODE
block config
on ctl 'echo "password: $(cat .netops-password)" >> .gnmic.yaml; chmod 600 .gnmic.yaml'
block capabilities
on ctl 'gnmic -a edge1.example.net:9339 capabilities'
block get-leaf
on ctl 'gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/state/oper-status"'
block get-wildcard
on ctl 'gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=*]/state/counters/in-octets"'
block get-container
on ctl 'gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/config"'
block get-missing
on ctl 'gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth9]/state"'
block sample
on ctl 'timeout 5 gnmic -a edge1.example.net:9339 subscribe --path "/interfaces/interface[name=eth1]/state/counters/in-octets" --stream-mode sample --sample-interval 2s'

put rate.py <<'CODE'
from pathlib import Path

from pygnmi.client import gNMIclient, telemetryParser

PATH = "/interfaces/interface[name=eth1]/state/counters"
SUB = {"mode": "stream", "encoding": "json",
       "subscription": [{"path": PATH, "mode": "sample", "sample_interval": 2_000_000_000}]}
password = Path("~/.netops-password").expanduser().read_text().strip()

with gNMIclient(target=("edge1.example.net", 9339), username="netops",
                password=password, path_root="lab-ca.pem") as gc:
    stream = gc.subscribe(subscribe=SUB)
    last = None
    for n, response in enumerate(stream):
        msg = telemetryParser(response)
        if "update" not in msg:
            continue
        values = {u["path"].rsplit("/", 1)[1]: u["val"] for u in msg["update"]["update"]}
        now = (msg["update"]["timestamp"], values["in-octets"], values["out-octets"])
        if last:
            seconds = (now[0] - last[0]) / 1e9
            rx = (now[1] - last[1]) * 8 / seconds / 1000
            tx = (now[2] - last[2]) * 8 / seconds / 1000
            print(f"{seconds:5.2f} s   in {rx:7.1f} kbit/s   out {tx:7.1f} kbit/s")
        last = now
        if n == 6:
            stream.cancel()
            break
CODE
bgon pc1 'ping -q -i 0.05 -s 1200 -c 300 203.0.113.74' 1
block rate
on ctl 'python rate.py'
block rate-ping
fgon

put watch.py <<'CODE'
from datetime import datetime
from pathlib import Path

from pygnmi.client import gNMIclient, telemetryParser

SUB = {"mode": "stream", "encoding": "json",
       "subscription": [{"path": "/interfaces/interface[name=eth2]/state/oper-status",
                         "mode": "on_change"}]}
password = Path("~/.netops-password").expanduser().read_text().strip()

with gNMIclient(target=("edge2.example.net", 9339), username="netops",
                password=password, path_root="lab-ca.pem") as gc:
    stream = gc.subscribe(subscribe=SUB)
    seen = 0
    for response in stream:
        msg = telemetryParser(response)
        if "update" not in msg:
            continue
        for u in msg["update"]["update"]:
            when = datetime.fromtimestamp(msg["update"]["timestamp"] / 1e9).strftime("%H:%M:%S.%f")[:-3]
            print(f"{when}  edge2 eth2 is {u['val']}")
        seen += 1
        if seen == 3:
            stream.cancel()
            break
CODE
bgon ctl 'python watch.py' 2
block on-change-set
on ctl 'gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value false'
sleep 3
on ctl 'gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value true'
block on-change-watch
fgon

block set
on ctl 'gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/description" --update-value "branch 1 LAN"'
on ctl 'ssh netops@edge1 "show running-config" | grep -A1 "interface eth2"'
block set-refused
on ctl 'gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/mtu" --update-value 9000'
block wrong-password
on ctl 'gnmic -a edge1.example.net:9339 -p guess capabilities'
