#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nornir 3.6.0 with nornir_napalm 0.6.0, NAPALM 5.2.0 with napalm_frr (the
# lab's driver, lesson 8), netutils 1.19.2 and Ubuntu 24.04's git.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the files lessons 8 and 10 left in ana's home
# (put below, at their places there), which pulling.md copies into ~/net; the
# files ana wrote; and edge2's SSH server, stopped before the failed backup
# and started again after it, with the commands failure.md gives.
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
# lessons 8 and 10 as they left ana's home: their files, which those lessons show

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
put net/backup.py <<'CODE'
import pathlib
import subprocess
import sys

from nornir import InitNornir
from nornir_napalm.plugins.tasks import napalm_get

nr = InitNornir(config_file="config.yaml")
result = nr.run(task=napalm_get, getters=["config"], getters_options={"config": {"retrieve": "running"}})

repo = pathlib.Path("backups")
for host, r in sorted(result.items()):
    if r.failed:
        print(f"{host}: FAILED, kept the previous copy: {str(r[0].exception).splitlines()[0]}")
        continue
    (repo / f"{host}.conf").write_text(r[0].result["config"]["running"])


def git(*args):
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True, check=True).stdout


git("add", "--all")
changed = git("diff", "--cached", "--name-only").split()
if changed:
    git("commit", "--quiet", "-m", "backup: " + ", ".join(f.removesuffix(".conf") for f in changed))
    print("committed:", ", ".join(changed))
else:
    print("no change since the last backup")
sys.exit(1 if result.failed else 0)
CODE
put net/compare.py <<'CODE'
import pathlib
import sys

from netutils.config.compliance import diff_network_config

host = sys.argv[1]
intended = pathlib.Path(f"configs/{host}.conf").read_text()
actual = pathlib.Path(f"backups/{host}.conf").read_text()
missing = diff_network_config(intended, actual, "cisco_ios")
extra = diff_network_config(actual, intended, "cisco_ios")
print(f"{host}, missing from the router:\n{missing or '(nothing)'}")
print(f"{host}, on the router and not intended:\n{extra or '(nothing)'}")
CODE
put net/restore.py <<'CODE'
import sys

from napalm import get_network_driver

host, filename = sys.argv[1], sys.argv[2]
driver = get_network_driver("frr")
with driver(host, "netops", None, optional_args={"key_file": "/home/ana/.ssh/id_ed25519"}) as dev:
    dev.load_replace_candidate(filename=filename)
    print(dev.compare_config() or "nothing to restore")
    if "--commit" in sys.argv:
        dev.commit_config()
        print("restored")
    else:
        dev.discard_config()
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

block setup
on ctl 'git config --global user.name ana && git config --global user.email ana@example.net && git config --global init.defaultBranch main'
on ctl 'mkdir -p net/inventory net/templates && cp config.yaml net/ && cp inventory/groups.yaml inventory/defaults.yaml net/inventory/ && cp -r tpl/data tpl/render.py net/ && cp tpl/templates/frr.j2 net/templates/'
put net/inventory/hosts.yaml <<'CODE'
---
core1:
  hostname: core1.example.net
  groups: [routers]
edge1:
  hostname: edge1.example.net
  groups: [routers]
edge2:
  hostname: edge2.example.net
  groups: [routers]
CODE
block init
on ctl 'cd net && git init --quiet backups && ls'
block first
on ctl 'cd net && python backup.py'
on ctl 'cd net && git -C backups log --oneline'
block again
on ctl 'cd net && python backup.py'
quiet edge2 'kill $(cat /run/sshd-edge2.pid)'
block failed
on ctl 'cd net && python backup.py; echo "exit status $?"'
quiet edge2 '/usr/sbin/sshd -f /etc/ssh/sshd_config'
block drift-made
typed edge1 'configure terminal' 'interface eth2' 'description guest wifi' 'exit' 'ip route 192.0.2.128/25 198.51.100.1' 'end' 'exit'
block drift
on ctl 'cd net && python backup.py'
on ctl 'cd net && git -C backups log --oneline'
block drift-show
on ctl 'cd net && git -C backups show --stat HEAD'
on ctl 'cd net && diff <(git -C backups show HEAD~1:edge1.conf) backups/edge1.conf'
block plain-diff
on ctl 'cd net && python render.py > /dev/null && diff configs/edge1.conf backups/edge1.conf'
block compare
on ctl 'cd net && python compare.py edge1'
block restore-dry
on ctl 'cd net && git -C backups show HEAD~1:edge1.conf > edge1-before.conf && python restore.py edge1 edge1-before.conf'
block restore
on ctl 'cd net && python restore.py edge1 edge1-before.conf --commit'
on ctl 'cd net && python backup.py && git -C backups log --oneline'
on ctl 'cd net && python compare.py edge1'
