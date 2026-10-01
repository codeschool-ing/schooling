#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# NetBox v4.6.10 on the netbox host, seeded by lab.sh with the lab's devices,
# interfaces, addresses, prefixes and cables. pynetbox 7.8.0, nornir-netbox
# 0.3.0, Jinja2 3.1.6, NAPALM 5.2.0 with napalm_frr (lesson 8).
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, NetBox's contents included; ana's NetBox token
# in ~/.netbox-token; and the files ana wrote (put below), whose contents the
# lessons show, with lesson 10's template and push.py copied beside them.
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
lab exec ctl ana 'mkdir -p sot/templates sot/inventory'

put sot/nb.py <<'CODE'
import pynetbox


def connect():
    nb = pynetbox.api("https://netbox", token=open("/home/ana/.netbox-token").read().strip())
    nb.http_session.verify = "/home/ana/lab-ca.pem"
    return nb
CODE
put sot/show.py <<'CODE'
from nb import connect

nb = connect()
for device in nb.dcim.devices.filter(role="router"):
    print(f"{device.name}  site={device.site.slug}  platform={device.platform.slug}  mgmt={device.primary_ip4}")
    for ip in nb.ipam.ip_addresses.filter(device_id=device.id):
        print(f"    {ip.assigned_object.name:5} {ip.address}")
CODE
put sot/ospf_field.py <<'CODE'
from nb import connect

nb = connect()
choices = nb.extras.custom_field_choice_sets.create(
    name="OSPF interface", extra_choices=[["point-to-point", "point-to-point"], ["passive", "passive"]])
nb.extras.custom_fields.create(
    name="ospf", label="OSPF", type="select", object_types=["dcim.interface"], choice_set=choices.id)

OSPF = {("core1", "eth1"): "point-to-point", ("core1", "eth2"): "point-to-point",
        ("edge1", "eth1"): "point-to-point", ("edge1", "eth2"): "passive",
        ("edge2", "eth1"): "point-to-point", ("edge2", "eth2"): "passive"}
for (device, name), role in OSPF.items():
    interface = nb.dcim.interfaces.get(device=device, name=name)
    interface.custom_fields["ospf"] = role
    interface.save()
    print(f"{device} {name}: ospf={role}")
CODE
put sot/render_nb.py <<'CODE'
import ipaddress
import pathlib

from jinja2 import Environment, FileSystemLoader, StrictUndefined

from nb import connect


def network(address):
    return str(ipaddress.ip_interface(address).network)


env = Environment(loader=FileSystemLoader("templates"), trim_blocks=True, lstrip_blocks=True,
                  keep_trailing_newline=True, undefined=StrictUndefined)
env.filters["network"] = network
template = env.get_template("frr.j2")
nb = connect()
pathlib.Path("configs").mkdir(exist_ok=True)

for device in nb.dcim.devices.filter(role="router"):
    addresses = {ip.assigned_object.name: ip.address for ip in nb.ipam.ip_addresses.filter(device_id=device.id)}
    data = {
        "hostname": device.name,
        "loopback": addresses["lo"].split("/")[0],
        "interfaces": [
            {"name": i.name, "description": i.description, "address": addresses[i.name],
             "ospf": i.custom_fields["ospf"]}
            for i in nb.dcim.interfaces.filter(device_id=device.id, mgmt_only=False)
            if i.name != "lo"
        ],
    }
    text = template.render(data)
    pathlib.Path(f"configs/{device.name}.conf").write_text(text)
    print(f"NetBox -> configs/{device.name}.conf, {len(text.splitlines())} lines")
CODE
put sot/templates/frr.j2 <<'CODE'
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
put sot/push.py <<'CODE'
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
put sot/nb_config.yaml <<'CODE'
inventory:
  plugin: NetBoxInventory2
  options:
    nb_url: https://netbox
    ssl_verify: /home/ana/lab-ca.pem
    filter_parameters: {role: router}
    use_platform_slug: true
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
CODE
put sot/inventory/defaults.yaml <<'CODE'
---
username: netops
connection_options:
  napalm:
    extras:
      optional_args: {key_file: /home/ana/.ssh/id_ed25519}
CODE
put sot/nr_nb.py <<'CODE'
from nornir import InitNornir
from nornir_napalm.plugins.tasks import napalm_get

nr = InitNornir(config_file="nb_config.yaml")
for name, host in nr.inventory.hosts.items():
    print(f"{name}: hostname={host.hostname} platform={host.platform} site={host.data['site']['slug']}")

result = nr.run(task=napalm_get, getters=["facts"])
for name, r in sorted(result.items()):
    facts = r[0].result["facts"]
    print(f"{name}: {facts['vendor']} {facts['os_version']}, interfaces {', '.join(facts['interface_list'])}")
CODE
put sot/allocate.py <<'CODE'
import sys

from nb import connect

nb = connect()
prefix = nb.ipam.prefixes.get(prefix="203.0.113.0/26")
ip = prefix.available_ips.create({"status": "active", "description": sys.argv[1]})
print(f"{ip.address} for {ip.description}")
CODE
put sot/rename.py <<'CODE'
from nb import connect

nb = connect()
interface = nb.dcim.interfaces.get(device="edge2", name="eth2")
interface.description = "branch 2 LAN, floor 1"
interface.save()
print(f"edge2 eth2: {interface.description}")
CODE

block curl-devices
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/devices/?role=router&brief=1" | jq'
block curl-addresses
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/ipam/ip-addresses/?device=edge1" | jq -r ".results[] | [.assigned_object.name, .address] | @tsv"'
block show
on ctl 'cd sot && python show.py'
block render-before
on ctl 'cd sot && python render_nb.py 2>&1 | tail -1'
block ospf-field
on ctl 'cd sot && python ospf_field.py'
block refused
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/interfaces/?device=edge1&name=eth2" | jq ".results[0].id"'
on ctl 'curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat ~/.netbox-token)" -H "Content-Type: application/json" -d "{\"custom_fields\": {\"ospf\": \"p2p\"}}" https://netbox/api/dcim/interfaces/7/ | jq'
block render
on ctl 'cd sot && python render_nb.py'
on ctl 'cd sot && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done'
block nornir
on ctl 'cd sot && NB_TOKEN=$(cat ~/.netbox-token) python nr_nb.py'
block no-token
on ctl 'cd sot && python nr_nb.py 2>&1 | tail -1'
block allocate
on ctl 'cd sot && python allocate.py "printer, branch 1"'
on ctl 'cd sot && python allocate.py "printer, branch 1"'
block change
on ctl 'cd sot && python rename.py && python render_nb.py > /dev/null && python push.py'
block changelog
on ctl 'curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/core/object-changes/?changed_object_type=dcim.interface&ordering=-time&limit=1" | jq ".results[0] | {time, user_name, action, object_repr, before: .prechange_data.description, after: .postchange_data.description}"'
