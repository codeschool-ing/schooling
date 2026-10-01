#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# pydantic 2.13.5, pytest 9.1.1, Jinja2 3.1.6 and NAPALM 5.2.0 with napalm_frr
# (lesson 8), from the lab's virtual environment.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; ana's git identity; the files ana wrote (put
# below), whose contents the lesson shows, with lesson 10's data, template and
# push.py beside them; and two waits, for OSPF's dead interval to pass after
# the bad change, and twelve seconds and then ten more after the revert, which
# the lesson says.
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
lab exec ctl ana 'git config --global user.name ana && git config --global user.email ana@example.net && git config --global init.defaultBranch main && mkdir -p net/data net/templates'

put net/data/core1.yaml <<'CODE'
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
put net/data/edge1.yaml <<'CODE'
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
put net/data/edge2.yaml <<'CODE'
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
put net/templates/frr.j2 <<'CODE'
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
put net/render.py <<'CODE'
import ipaddress
import pathlib

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined


def network(address):
    return str(ipaddress.ip_interface(address).network)


env = Environment(loader=FileSystemLoader("templates"), trim_blocks=True, lstrip_blocks=True,
                  keep_trailing_newline=True, undefined=StrictUndefined)
env.filters["network"] = network
template = env.get_template("frr.j2")

if __name__ == "__main__":
    pathlib.Path("configs").mkdir(exist_ok=True)
    for path in sorted(pathlib.Path("data").glob("*.yaml")):
        data = yaml.safe_load(path.read_text())
        text = template.render(data)
        (pathlib.Path("configs") / f"{data['hostname']}.conf").write_text(text)
        print(f"{path} -> configs/{data['hostname']}.conf, {len(text.splitlines())} lines")
CODE
put net/push.py <<'CODE'
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
put net/model.py <<'CODE'
from ipaddress import IPv4Address, IPv4Interface
from typing import Literal

from pydantic import BaseModel, ConfigDict


class Interface(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str
    description: str = ""
    address: IPv4Interface
    ospf: Literal["point-to-point", "passive"] | None = None


class Router(BaseModel):
    model_config = ConfigDict(extra="forbid")
    hostname: str
    loopback: IPv4Address
    interfaces: list[Interface]
CODE
put net/validate.py <<'CODE'
import pathlib
import sys

import yaml
from pydantic import ValidationError

from model import Router

failed = False
for path in sorted(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "data").glob("*.yaml")):
    try:
        Router.model_validate(yaml.safe_load(path.read_text()))
        print(f"{path}: ok")
    except ValidationError as e:
        failed = True
        print(f"{path}: {e.error_count()} error(s)")
        for err in e.errors():
            print("   ", ".".join(str(p) for p in err["loc"]), "-", err["msg"])
sys.exit(1 if failed else 0)
CODE
put net/edge3.yaml <<'CODE'
hostname: edge3
loopback: 203.0.113.254
interfaces:
  - name: eth1
    description: uplink to core1
    adress: 198.51.100.10/30
    ospf: point-to-point
  - name: eth2
    description: branch LAN
    address: 203.0.113.300/26
    ospf: p2p
CODE
put net/test_configs.py <<'CODE'
import ipaddress
import pathlib
from collections import Counter

import pytest
import yaml

from model import Router
from render import template

ROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path("data").glob("*.yaml"))}


@pytest.mark.parametrize("name", ROUTERS)
def test_data_matches_the_model(name):
    Router.model_validate(ROUTERS[name])


def test_no_address_is_used_twice():
    addresses = Counter(i["address"].split("/")[0] for r in ROUTERS.values() for i in r["interfaces"])
    addresses.update(r["loopback"] for r in ROUTERS.values())
    assert [a for a, n in addresses.items() if n > 1] == []


@pytest.mark.parametrize("name", ROUTERS)
def test_every_ospf_interface_gets_a_network_line(name):
    config = template.render(ROUTERS[name])
    for i in ROUTERS[name]["interfaces"]:
        if i.get("ospf"):
            network = ipaddress.ip_interface(i["address"]).network
            assert f" network {network} area 0" in config.splitlines()
CODE
put net/test_network.py <<'CODE'
import ipaddress
import json
import pathlib
import subprocess

import pytest
import yaml

ROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path("data").glob("*.yaml"))}


def show(router, command):
    out = subprocess.run(["ssh", f"netops@{router}", command + " json"], capture_output=True, text=True,
                         check=True, timeout=15).stdout
    return json.loads(out)


@pytest.mark.parametrize("name", ROUTERS)
def test_ospf_neighbours_are_full(name):
    expected = sum(i.get("ospf") == "point-to-point" for i in ROUTERS[name]["interfaces"])
    neighbours = [n for ns in show(name, "show ip ospf neighbor")["neighbors"].values() for n in ns]
    assert [n["converged"] for n in neighbours] == ["Full"] * expected


LANS = [str(ipaddress.ip_interface(i["address"]).network)
        for r in ROUTERS.values() for i in r["interfaces"] if i.get("ospf") == "passive"]


@pytest.mark.parametrize("name", ROUTERS)
def test_every_branch_lan_is_routed(name):
    routes = show(name, "show ip route")
    assert [lan for lan in LANS if lan not in routes] == []
CODE
lab exec ctl ana 'cd net && printf "configs/\n__pycache__/\n.pytest_cache/\n" > .gitignore && git init -q && git add . && git commit -qm "lesson 10 project, with tests"'

block validate
on ctl 'cd net && python validate.py'
block validate-bad
on ctl 'cd net && mkdir -p new && cp edge3.yaml new/ && python validate.py new; echo "exit status $?"'
block yamllint
on ctl 'cd net && yamllint -d relaxed data/'
block offline
on ctl 'cd net && pytest -v test_configs.py'
block online
on ctl 'cd net && pytest -v test_network.py'
block bad-change
on ctl "cd net && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && diff <(git show HEAD:data/edge2.yaml) data/edge2.yaml"
on ctl 'cd net && python validate.py && pytest -q test_configs.py'
on ctl 'cd net && python render.py > /dev/null && python push.py --commit'
sleep 45
block after
on ctl 'cd net && pytest -q test_network.py'
block revert
on ctl 'cd net && git checkout data/edge2.yaml && python render.py > /dev/null && python push.py --commit'
sleep 12
on ctl 'cd net && pytest -q test_network.py | tail -4'
sleep 10
block revert-later
on ctl 'cd net && pytest -q test_network.py'
put net/test_links.py <<'CODE'
import ipaddress
import pathlib
from collections import defaultdict

import yaml

ROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path("data").glob("*.yaml"))}


def test_both_ends_of_a_link_agree():
    ends = defaultdict(list)
    for name, router in ROUTERS.items():
        for i in router["interfaces"]:
            net = ipaddress.ip_interface(i["address"]).network
            if net.prefixlen == 30:
                ends[str(net)].append(f"{name} {i['name']} ospf={i.get('ospf')}")
    for net, sides in ends.items():
        assert len(sides) == 2, f"{net} has {len(sides)} end(s): {sides}"
        assert sides[0].split("ospf=")[1] == sides[1].split("ospf=")[1], f"{net}: {sides}"
CODE
block links
on ctl "cd net && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && pytest -q test_configs.py test_links.py"
on ctl 'cd net && git checkout data/edge2.yaml && pytest -q test_configs.py test_links.py'
