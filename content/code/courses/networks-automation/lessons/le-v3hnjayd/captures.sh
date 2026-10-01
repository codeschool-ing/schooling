#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; nc.py, lesson 3's NETCONF helper, copied into
# ana's home; and the files ana wrote (put below), whose contents the lesson
# shows. PyYAML is 6.0.3, xmltodict 1.0.4, yamllint 1.33.0.
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
put nc.py <<'CODE'
from ncclient import manager

IF = "urn:ietf:params:xml:ns:yang:ietf-interfaces"
NS = {"if": IF}


def connect():
    return manager.connect(host="nc1.example.net", port=830, username="netops",
                           key_filename="/home/ana/.ssh/id_ed25519", hostkey_verify=True)


def interface_config(body):
    return (f'<config xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">'
            f'<interfaces xmlns="{IF}">{body}</interfaces></config>')


def describe(m, source, name):
    """The description and enabled leaves of one interface, read from a datastore."""
    xpath = f"/if:interfaces/if:interface[if:name='{name}']"
    data = m.get_config(source=source, filter=("xpath", (NS, xpath))).data
    desc = data.findtext(".//if:description", default="(none)", namespaces=NS)
    enabled = data.findtext(".//if:enabled", namespaces=NS)
    return f"{source:<9} {name}: description={desc!r} enabled={enabled}"
CODE

put eth1.yaml <<'CODE'
# The same interface, written by a person for a file in a repository.
name: eth1
description: uplink to core1
type: ethernetCsmacd
enabled: true
ipv4:
  address:
    - ip: 198.51.100.2
      prefix-length: 30
CODE
put three.py <<'CODE'
import json

import requests
import yaml

from nc import NS, connect

with connect() as m:
    xml = m.get_config(source="running", filter=("xpath", (NS, "/if:interfaces/if:interface[if:name='eth1']"))).data_xml
print(xml)

r = requests.get("https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth1",
                 headers={"Accept": "application/yang-data+json"}, verify="lab-ca.pem", timeout=10)
print(r.text)

print(json.dumps(yaml.safe_load(open("eth1.yaml")), indent=1))
CODE
block three
on ctl 'python three.py'

put types.py <<'CODE'
import json

text = '{"name": "eth1", "mtu": 1500, "enabled": true, "speed": null, "load": 0.25, "addresses": ["198.51.100.2/30"]}'
data = json.loads(text)
for key, value in data.items():
    print(f"{key:10} {type(value).__name__:6} {value!r}")

print(json.dumps(data, sort_keys=True, indent=2))
CODE
block types
on ctl 'python types.py'

put xml_read.py <<'CODE'
import xml.etree.ElementTree as ET

REPLY = """<data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces">
    <interface>
      <name>eth1</name>
      <description>uplink to core1</description>
      <ipv4 xmlns="urn:ietf:params:xml:ns:yang:ietf-ip">
        <address><ip>198.51.100.2</ip><prefix-length>30</prefix-length></address>
      </ipv4>
    </interface>
  </interfaces>
</data>"""

root = ET.fromstring(REPLY)
print(root[0][0].tag)
print(root.findall(".//interface"))
NS = {"if": "urn:ietf:params:xml:ns:yang:ietf-interfaces", "ip": "urn:ietf:params:xml:ns:yang:ietf-ip"}
for i in root.findall(".//if:interface", NS):
    print(i.findtext("if:name", namespaces=NS), i.findtext("ip:ipv4/ip:address/ip:prefix-length", namespaces=NS))
CODE
block xml-read
on ctl 'python xml_read.py'

put surprises.yaml <<'CODE'
country: NO
enable_ntp: on
file_mode: 0755
version: 1.10
port_range: 22:22
vlan_name: 010
CODE
put surprises.py <<'CODE'
import yaml

for key, value in yaml.safe_load(open("surprises.yaml")).items():
    print(f"{key:11} {type(value).__name__:5} {value!r}")
CODE
block surprises
on ctl 'python surprises.py'
block quoted
on ctl "sed -E 's/: (.*)$/: \"\\1\"/' surprises.yaml > quoted.yaml; cat quoted.yaml"
on ctl "python -c 'import yaml; print(yaml.safe_load(open(\"quoted.yaml\")))'"

block unsafe
on ctl "python -c 'import yaml; yaml.safe_load(\"!!python/object/apply:os.system [echo hello]\")' 2>&1 | grep Error"

put single.py <<'CODE'
import json

import xmltodict

ONE = "<interfaces><interface><name>eth1</name></interface></interfaces>"
TWO = "<interfaces><interface><name>eth1</name></interface><interface><name>eth2</name></interface></interfaces>"

print(json.dumps(xmltodict.parse(ONE)))
print(json.dumps(xmltodict.parse(TWO)))
print(json.dumps(xmltodict.parse(ONE, force_list=("interface",))))
CODE
block single
on ctl 'python single.py'

put inventory.yaml <<'CODE'
routers:
  core1:
    address: 192.0.2.11
    site: core
  edge1:
    address: 192.0.2.12
    site: branch-1
  edge1:
    address: 192.0.2.13
    site: branch-2
CODE
block duplicate
on ctl "python -c 'import yaml; print(yaml.safe_load(open(\"inventory.yaml\")))'"
on ctl 'yamllint inventory.yaml; echo "exit status $?"'
block json-check
on ctl "printf '{\"name\": \"eth1\", \"mtu\": 1500,}\\n' > bad.json; python -m json.tool bad.json; echo \"exit status \$?\""
block xml-check
on ctl "printf '<interface><name>eth1</interface>\\n' > bad.xml; xmllint --noout bad.xml; echo \"exit status \$?\""
