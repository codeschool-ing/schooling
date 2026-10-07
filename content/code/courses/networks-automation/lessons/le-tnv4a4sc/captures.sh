#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The libraries are Paramiko 5.0.0, Netmiko 4.8.0, NAPALM 5.2.0, Nornir 3.6.0
# with nornir-netmiko 1.0.1 and nornir-napalm 0.6.0. The NAPALM driver named
# frr is napalm_frr, written for the lab and printed in full in a-driver.md:
# NAPALM ships no FRR driver.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; and the files ana wrote (put below), whose
# contents the lesson shows.
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

put para.py <<'CODE'
import paramiko

client = paramiko.SSHClient()
client.load_system_host_keys("/home/ana/.ssh/known_hosts")
client.set_missing_host_key_policy(paramiko.RejectPolicy())
client.connect("edge1", username="netops", key_filename="/home/ana/.ssh/id_ed25519")

stdin, stdout, stderr = client.exec_command("show ip ospf neighbor")
print(stdout.read().decode())
print("exit status", stdout.channel.recv_exit_status())
client.close()
CODE
block paramiko
on ctl 'python para.py'
put nm.py <<'CODE'
from netmiko import ConnectHandler

edge1 = ConnectHandler(device_type="cisco_ios", host="edge1", username="netops",
                       use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
print(repr(edge1.find_prompt()))
print(edge1.send_command("show ip route ospf"))
edge1.disconnect()
CODE
block netmiko
on ctl 'python nm.py'
put neighbours.py <<'CODE'
import json

from netmiko import ConnectHandler

ROUTERS = ["core1", "edge1", "edge2"]

for name in ROUTERS:
    router = ConnectHandler(device_type="cisco_ios", host=name, username="netops",
                            use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
    data = json.loads(router.send_command("show ip ospf neighbor json"))
    router.disconnect()
    for neighbour, entries in data["neighbors"].items():
        for n in entries:
            print(f"{name:6} sees {neighbour:15} on {n['ifaceName']:18} state {n['nbrState']}")
CODE
block json
on ctl 'ssh netops@core1 "show ip ospf neighbor json" | head -14'
block neighbours
on ctl 'python neighbours.py'
put nm_config.py <<'CODE'
from netmiko import ConnectHandler

LINES = ["interface eth2", "descripton branch 1 LAN"]

edge1 = ConnectHandler(device_type="cisco_ios", host="edge1", username="netops",
                       use_keys=True, key_file="/home/ana/.ssh/id_ed25519")
print(edge1.send_config_set(LINES))
print("-- the same lines, with error_pattern")
try:
    edge1.send_config_set(LINES, error_pattern=r"% ")
except Exception as e:
    print(type(e).__name__, "-", str(e).splitlines()[0])
edge1.disconnect()
CODE
block nm-config
on ctl 'python nm_config.py'

put facts.py <<'CODE'
import json

from napalm import get_network_driver

driver = get_network_driver("frr")
with driver("edge1", "netops", None, optional_args={"key_file": "/home/ana/.ssh/id_ed25519"}) as dev:
    print(json.dumps(dev.get_facts(), indent=2))
    print(json.dumps(dev.get_interfaces_ip(), indent=2))
CODE
block facts
on ctl 'python facts.py'
put candidate.py <<'CODE'
import sys

from napalm import get_network_driver

driver = get_network_driver("frr")
with driver("edge1", "netops", None, optional_args={"key_file": "/home/ana/.ssh/id_ed25519"}) as dev:
    dev.load_replace_candidate(filename="edge1.conf")
    diff = dev.compare_config()
    if not diff:
        print("edge1 already matches edge1.conf")
        dev.discard_config()
        sys.exit()
    print(diff)
    if "--commit" in sys.argv:
        dev.commit_config()
        print("committed")
    else:
        dev.discard_config()
        print("discarded (run with --commit to apply)")
CODE
block candidate-prepare
on ctl 'ssh netops@edge1 "show running-config" > edge1.conf'
on ctl "sed -i 's/description branch LAN/description branch 1 LAN, floor 2/' edge1.conf"
on ctl "sed -i 's/^router ospf/ip route 192.0.2.128\\/25 198.51.100.1\\n!\\nrouter ospf/' edge1.conf"
block candidate-dry
on ctl 'python candidate.py'
block candidate-commit
on ctl 'python candidate.py --commit'
on ctl 'python candidate.py'
put rollback.py <<'CODE'
from napalm import get_network_driver

ROUTE = "ip route 198.51.100.128/25 198.51.100.1"

driver = get_network_driver("frr")
with driver("edge1", "netops", None, optional_args={"key_file": "/home/ana/.ssh/id_ed25519"}) as dev:
    dev.load_merge_candidate(config=ROUTE + "\n")
    print(dev.compare_config())
    dev.commit_config()
    print("after commit:  ", ROUTE in dev.get_config()["running"])
    dev.rollback()
    print("after rollback:", ROUTE in dev.get_config()["running"])
CODE
block rollback
on ctl 'python rollback.py'

put config.yaml <<'CODE'
inventory:
  plugin: SimpleInventory
  options:
    host_file: inventory/hosts.yaml
    group_file: inventory/groups.yaml
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
CODE
put inventory/hosts.yaml <<'CODE'
---
core1:
  hostname: core1.example.net
  groups: [routers]
  data: {site: core}
edge1:
  hostname: edge1.example.net
  groups: [routers]
  data: {site: branch-1}
edge2:
  hostname: edge2.example.net
  groups: [routers]
  data: {site: branch-2}
edge3:
  hostname: edge3.example.net
  groups: [routers]
  data: {site: branch-3}
CODE
put inventory/groups.yaml <<'CODE'
---
routers:
  platform: cisco_ios
  connection_options:
    napalm:
      platform: frr
      extras:
        optional_args: {key_file: /home/ana/.ssh/id_ed25519}
CODE
put inventory/defaults.yaml <<'CODE'
---
username: netops
connection_options:
  netmiko:
    extras: {use_keys: true, key_file: /home/ana/.ssh/id_ed25519}
CODE
put nr.py <<'CODE'
import json

from nornir import InitNornir
from nornir_netmiko.tasks import netmiko_send_command

nr = InitNornir(config_file="config.yaml")
print("hosts:", ", ".join(nr.inventory.hosts))


def full_neighbours(task):
    out = task.run(netmiko_send_command, command_string="show ip ospf neighbor json")
    data = json.loads(out.result)
    return sum(n["nbrState"].startswith("Full") for e in data["neighbors"].values() for n in e)


result = nr.run(task=full_neighbours)
for host, r in sorted(result.items()):
    if r.failed:
        print(f"{host:6} FAILED: {type(r[-1].exception).__name__}: {str(r[-1].exception).splitlines()[0]}")
    else:
        print(f"{host:6} {r[0].result} OSPF neighbour(s) Full")
print("failed hosts:", sorted(result.failed_hosts))
CODE
block nornir
on ctl 'time python nr.py'
put nr_filter.py <<'CODE'
from nornir import InitNornir
from nornir.core.filter import F
from nornir_napalm.plugins.tasks import napalm_get

nr = InitNornir(config_file="config.yaml")
branches = nr.filter(F(site__startswith="branch-") & ~F(name="edge3"))
print("selected:", ", ".join(branches.inventory.hosts))
result = branches.run(task=napalm_get, getters=["facts"])
for host, r in sorted(result.items()):
    facts = r[0].result["facts"]
    print(host, facts["vendor"], facts["os_version"], len(facts["interface_list"]), "interfaces")
CODE
block nornir-filter
on ctl 'python nr_filter.py'
