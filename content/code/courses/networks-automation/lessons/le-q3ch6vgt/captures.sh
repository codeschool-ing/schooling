#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds three FRR
# routers, a NETCONF device, NetBox and a service desk out of network
# namespaces on one Linux computer, and ctl, the machine ana works from. A line
# that starts with ana@ctl ran on ctl; a line that starts with core1# was typed
# at core1's CLI over SSH.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, and the files ana wrote (put below), whose
# contents the lesson shows in full.
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

lab reset

block by-hand-core1
typed core1 'configure terminal' 'ip prefix-list MGMT seq 10 permit 192.0.2.0/24' 'end' 'write memory' 'exit'
block by-hand-edge1
typed edge1 'configure terminal' 'ip prefix-list MGMT seq 10 permit 192.0.12.0/24' 'end' 'write memory' 'exit'
block check-by-hand
on ctl 'for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done'

put mgmt.py <<'CODE'
from netmiko import ConnectHandler

ROUTERS = ["core1", "edge1", "edge2"]
LINE = "ip prefix-list MGMT seq 10 permit 192.0.2.0/24"

for name in ROUTERS:
    router = ConnectHandler(device_type="cisco_ios", host=name, username="netops",
                            use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
    router.send_config_set([LINE])
    router.save_config()
    router.disconnect()
    print(f"{name}: MGMT set")
CODE
block run-mgmt
on ctl 'time python mgmt.py'
block check-after
on ctl 'for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done'

put mgmt_check.py <<'CODE'
from netmiko import ConnectHandler

ROUTERS = ["core1", "edge1", "edge2"]
WANT = "ip prefix-list MGMT seq 10 permit 192.0.2.0/24"

for name in ROUTERS:
    router = ConnectHandler(device_type="cisco_ios", host=name, username="netops",
                            use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
    running = router.send_command("show running-config")
    if WANT in running.splitlines():
        print(f"{name}: already as intended")
    else:
        router.send_config_set([WANT])
        router.save_config()
        print(f"{name}: changed")
    router.disconnect()
CODE
block run-check
on ctl 'python mgmt_check.py'
block drift
typed edge2 'configure terminal' 'no ip prefix-list MGMT' 'end' 'write memory' 'exit'
block run-check-again
on ctl 'python mgmt_check.py'
on ctl 'python mgmt_check.py'

put intent.yaml <<'CODE'
management_network: 192.0.2.0/24
routers:
  - core1
  - edge1
  - edge2
CODE
put apply.py <<'CODE'
import ipaddress
import sys

import yaml
from netmiko import ConnectHandler

intent = yaml.safe_load(open("intent.yaml"))

try:
    net = ipaddress.ip_network(intent["management_network"])
except ValueError as e:
    sys.exit(f"refused: {e}")
if not net.subnet_of(ipaddress.ip_network("192.0.2.0/24")):
    sys.exit(f"refused: {net} is not inside the management range 192.0.2.0/24")

want = f"ip prefix-list MGMT seq 10 permit {net}"
for name in intent["routers"]:
    router = ConnectHandler(device_type="cisco_ios", host=name, username="netops",
                            use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
    if want not in router.send_command("show running-config").splitlines():
        router.send_config_set([want])
        router.save_config()
    ok = want in router.send_command("show running-config").splitlines()
    router.disconnect()
    print(f"{name}: {'verified' if ok else 'NOT as intended'}")
CODE
block apply
on ctl 'python apply.py'
block apply-refused
on ctl "sed -i 's#192.0.2.0/24#192.0.12.0/24#' intent.yaml"
on ctl 'python apply.py; echo "exit status $?"'

block lab-hosts
on ctl 'grep example.net /etc/hosts'
block lab-ctl
on ctl 'ip -br addr'
on ctl 'python --version'
on ctl 'pip list 2>/dev/null | grep -iE "^(netmiko|napalm|nornir|ncclient|pygnmi|jinja2|pynetbox) "'
block lab-router
on ctl 'ssh netops@edge1 "show version" | head -1'
on ctl 'ssh netops@edge1 "show ip ospf neighbor"'
on ctl 'ssh netops@edge1 "show ip route ospf"'
block lab-checks
on ctl 'ping -c 1 edge1'
on ctl 'nc -vz edge1 22'
