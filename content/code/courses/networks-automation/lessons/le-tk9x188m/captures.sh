#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Jinja2 is 3.1.6 and PyYAML 6.0.3, from the lab's virtual environment; NAPALM
# talks to FRR through napalm_frr, the driver written for the lab (lesson 8).
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, and the files ana wrote (put below), whose
# contents the lesson shows. render.py is written twice: first without
# keep_trailing_newline, which is the run the lesson's first comparison
# quotes, and then as the lesson shows it.
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
lab exec ctl ana 'mkdir -p tpl/data tpl/templates'

put tpl/first.py <<'CODE'
from jinja2 import Environment

TEMPLATE = """hostname {{ hostname }}
{% for i in interfaces %}
interface {{ i.name }}
 description {{ i.description | upper }}
exit
{% endfor %}"""

data = {
    "hostname": "edge1",
    "interfaces": [
        {"name": "eth1", "description": "uplink to core1"},
        {"name": "eth2", "description": "branch LAN"},
    ],
}

template = Environment().from_string(TEMPLATE)
print(template.render(data))
CODE
put tpl/data/core1.yaml <<'CODE'
hostname: core1
loopback: 203.0.113.251
interfaces:
  - name: eth1
    description: link to edge1
    address: 198.51.100.1/30
    ospf: point-to-point
  - name: eth2
    description: link to edge2
    address: 198.51.100.5/30
    ospf: point-to-point
CODE
put tpl/data/edge1.yaml <<'CODE'
hostname: edge1
loopback: 203.0.113.252
interfaces:
  - name: eth1
    description: uplink to core1
    address: 198.51.100.2/30
    ospf: point-to-point
  - name: eth2
    description: branch LAN
    address: 203.0.113.1/26
    ospf: passive
CODE
put tpl/data/edge2.yaml <<'CODE'
hostname: edge2
loopback: 203.0.113.253
interfaces:
  - name: eth1
    description: uplink to core1
    address: 198.51.100.6/30
    ospf: point-to-point
  - name: eth2
    description: branch LAN
    address: 203.0.113.65/26
    ospf: passive
CODE
put tpl/templates/iface.j2 <<'CODE'
{% for i in interfaces %}
interface {{ i.name }}
  {% if i.description %}
 description {{ i.description }}
  {% endif %}
 ip address {{ i.address }}
exit
{% endfor %}
CODE
put tpl/templates/frr.j2 <<'CODE'
frr version 8.4.4
frr defaults traditional
hostname {{ hostname }}
log file /var/log/frr/frr.log informational
service integrated-vtysh-config
!
{% for i in interfaces %}
interface {{ i.name }}
{% if i.description %}
 description {{ i.description }}
{% endif %}
 ip address {{ i.address }}
{% if i.ospf == "point-to-point" %}
 ip ospf network point-to-point
{% elif i.ospf == "passive" %}
 ip ospf passive
{% endif %}
exit
!
{% endfor %}
interface lo
 ip address {{ loopback }}/32
exit
!
router ospf
 ospf router-id {{ loopback }}
 redistribute connected
{% for i in interfaces if i.ospf %}
 network {{ i.address | network }} area 0
{% endfor %}
exit
!
line vty
 exec-timeout 30 0
exit
!
end
CODE
put tpl/spacing.py <<'CODE'
import sys

import yaml
from jinja2 import Environment, FileSystemLoader

data = yaml.safe_load(open("data/edge1.yaml"))
trim = "--trim" in sys.argv
env = Environment(loader=FileSystemLoader("templates"), trim_blocks=trim, lstrip_blocks=trim)
print(env.get_template("iface.j2").render(data), end="")
CODE
put tpl/missing.py <<'CODE'
import sys

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined, Undefined

data = yaml.safe_load(open("data/edge1.yaml"))
data["interfaces"][1]["adress"] = data["interfaces"][1].pop("address")

strict = "--strict" in sys.argv
env = Environment(loader=FileSystemLoader("templates"), trim_blocks=True, lstrip_blocks=True,
                  undefined=StrictUndefined if strict else Undefined)
print(env.get_template("iface.j2").render(data), end="")
CODE
put tpl/render.py <<'CODE'
import ipaddress
import pathlib

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined


def network(address):
    return str(ipaddress.ip_interface(address).network)


env = Environment(
    loader=FileSystemLoader("templates"),
    trim_blocks=True,
    lstrip_blocks=True,
    undefined=StrictUndefined,
)
env.filters["network"] = network
template = env.get_template("frr.j2")

out = pathlib.Path("configs")
out.mkdir(exist_ok=True)
for path in sorted(pathlib.Path("data").glob("*.yaml")):
    data = yaml.safe_load(path.read_text())
    text = template.render(data)
    (out / f"{data['hostname']}.conf").write_text(text)
    print(f"{path} -> configs/{data['hostname']}.conf, {len(text.splitlines())} lines")
CODE
put tpl/push.py <<'CODE'
import sys

from napalm import get_network_driver

driver = get_network_driver("frr")
for host in ("core1", "edge1", "edge2"):
    with driver(host, "netops", None, optional_args={"key_file": "/home/ana/.ssh/id_ed25519"}) as dev:
        dev.load_replace_candidate(filename=f"configs/{host}.conf")
        diff = dev.compare_config()
        if not diff:
            print(f"{host}: matches")
            dev.discard_config()
            continue
        print(f"{host}:\n{diff}")
        if "--commit" in sys.argv:
            dev.commit_config()
            print(f"{host}: committed")
        else:
            dev.discard_config()
CODE

block first
on ctl 'cd tpl && python first.py'
block spacing
on ctl 'cd tpl && python spacing.py'
block spacing-trim
on ctl 'cd tpl && python spacing.py --trim'
block missing
on ctl 'cd tpl && python missing.py'
block missing-strict
on ctl 'cd tpl && python missing.py --strict 2>&1 | tail -4'
block tree
on ctl 'cd tpl && find data templates -type f | sort'
block render
on ctl 'cd tpl && python render.py'
block compare-first
on ctl 'cd tpl && ssh netops@core1 "show running-config" | tail -n +5 | diff - configs/core1.conf'
put tpl/render.py <<'CODE'
import ipaddress
import pathlib

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined


def network(address):
    return str(ipaddress.ip_interface(address).network)


env = Environment(
    loader=FileSystemLoader("templates"),
    trim_blocks=True,
    lstrip_blocks=True,
    undefined=StrictUndefined,
    keep_trailing_newline=True,
)
env.filters["network"] = network
template = env.get_template("frr.j2")

out = pathlib.Path("configs")
out.mkdir(exist_ok=True)
for path in sorted(pathlib.Path("data").glob("*.yaml")):
    data = yaml.safe_load(path.read_text())
    text = template.render(data)
    (out / f"{data['hostname']}.conf").write_text(text)
    print(f"{path} -> configs/{data['hostname']}.conf, {len(text.splitlines())} lines")
CODE
block compare
on ctl 'cd tpl && python render.py'
on ctl 'cd tpl && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done'
block edge1
on ctl 'cd tpl && cat configs/edge1.conf'
block change
on ctl "cd tpl && sed -i 's/description: branch LAN/description: branch 2 LAN, floor 1/' data/edge2.yaml && python render.py"
block push-dry
on ctl 'cd tpl && python push.py'
block push
on ctl 'cd tpl && python push.py --commit'
on ctl 'cd tpl && python push.py'
block drift
typed edge1 'configure terminal' 'ip route 192.0.2.128/25 198.51.100.1' 'end' 'exit'
on ctl 'cd tpl && python push.py'
