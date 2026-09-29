#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The device is nc1: Clixon (built from the commit named in lab.sh), serving
# ietf-interfaces, ietf-ip and iana-if-type over NETCONF on port 830 and
# RESTCONF on 443. It has no forwarding plane; its configuration is a document
# Clixon validates and stores. The one piece of nc1 written for the lab is the
# plugin that checks a RESTCONF password.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, including ~/.netrc on ctl; and the files ana
# wrote (put below), whose contents the lesson shows.
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

put frames.py <<'CODE'
# Split NETCONF 1.0 messages on their end marker and indent each one, so a
# person can read what went over the wire. The bytes themselves are unchanged.
import sys
from xml.dom import minidom

for message in sys.stdin.read().split("]]>]]>"):
    if message.strip():
        print(minidom.parseString(message.strip()).toprettyxml(indent="  ").split("\n", 1)[1].rstrip())
        print("]]>]]>")
CODE
put hello.xml <<'CODE'
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities><capability>urn:ietf:params:netconf:base:1.0</capability></capabilities>
</hello>]]>]]>
<rpc message-id="1" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <get-config><source><running/></source>
    <filter type="subtree">
      <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces"><interface><name>eth1</name></interface></interfaces>
    </filter>
  </get-config>
</rpc>]]>]]>
<rpc message-id="2" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><close-session/></rpc>]]>]]>
CODE
block by-hand
on ctl '(cat hello.xml; sleep 2) | ssh -p 830 -s netops@nc1.example.net netconf | python3 frames.py'

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
put read.py <<'CODE'
from nc import NS, connect

with connect() as m:
    for c in ("candidate", "confirmed-commit", "validate"):
        print(c, any(f":{c}:" in cap for cap in m.server_capabilities))
    reply = m.get_config(source="running", filter=("xpath", (NS, "/if:interfaces/if:interface/if:description")))
    for i in reply.data.findall(".//if:interface", NS):
        print(i.findtext("if:name", namespaces=NS), "-", i.findtext("if:description", namespaces=NS))
CODE
block read
on ctl 'python read.py'

put candidate.py <<'CODE'
from nc import connect, describe, interface_config

with connect() as m:
    m.edit_config(target="candidate", config=interface_config(
        "<interface><name>eth2</name><description>to pc1</description><enabled>true</enabled></interface>"))
    print(describe(m, "candidate", "eth2"))
    print(describe(m, "running", "eth2"))
    m.commit()
    print("-- after commit")
    print(describe(m, "running", "eth2"))
CODE
block candidate
on ctl 'python candidate.py'

put invalid.py <<'CODE'
from ncclient.operations import RPCError

from nc import connect, interface_config

BAD = """<interface><name>eth2</name>
  <ipv4 xmlns="urn:ietf:params:xml:ns:yang:ietf-ip">
    <address><ip>192.0.2.99</ip><prefix-length>33</prefix-length></address>
  </ipv4></interface>"""

with connect() as m:
    m.edit_config(target="candidate", config=interface_config(BAD))
    print("edit-config: ok")
    try:
        m.validate(source="candidate")
    except RPCError as e:
        print("validate:", e.tag)
        print(" ", e.message)
    m.discard_changes()
    print("discard-changes: ok")
CODE
block invalid
on ctl 'python invalid.py'

put transaction.py <<'CODE'
from ncclient.operations import RPCError

from nc import connect, describe, interface_config

with connect() as m:
    m.edit_config(target="candidate", config=interface_config(
        "<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>"
        "<interface><name>eth3</name></interface>"))
    try:
        m.commit()
    except RPCError as e:
        print("commit:", e.tag, "-", e.message.split(".")[0])
    print(describe(m, "running", "eth1"))
    print(describe(m, "candidate", "eth1"))
    m.discard_changes()
    print(describe(m, "candidate", "eth1"))
CODE
block transaction
on ctl 'python transaction.py'

block no-namespace
on ctl "python -c 'from nc import connect; connect().edit_config(target=\"candidate\", config=\"<config><interfaces xmlns=\\\"urn:ietf:params:xml:ns:yang:ietf-interfaces\\\"/></config>\")' 2>&1 | tail -1"

put confirmed.py <<'CODE'
import time

from nc import connect, describe, interface_config

with connect() as m:
    m.edit_config(target="candidate", config=interface_config(
        "<interface><name>eth1</name><enabled>false</enabled></interface>"))
    m.commit(confirmed=True, timeout="10")
    print("t=0 ", describe(m, "running", "eth1"))
    time.sleep(5)
    print("t=5 ", describe(m, "running", "eth1"))
    time.sleep(8)
    print("t=13", describe(m, "running", "eth1"))
    print("    ", describe(m, "candidate", "eth1"))
    m.discard_changes()
CODE
block confirmed
on ctl 'python confirmed.py'
put confirmed_ok.py <<'CODE'
from nc import connect, describe, interface_config

with connect() as m:
    m.edit_config(target="candidate", config=interface_config(
        "<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>"))
    m.commit(confirmed=True, timeout="60")
    print(describe(m, "running", "eth1"))
    m.commit()
    print("confirmed")
CODE
block confirmed-ok
on ctl 'python confirmed_ok.py'

put locks.py <<'CODE'
from ncclient.operations import RPCError

from nc import connect, interface_config

EDIT = interface_config("<interface><name>eth2</name><description>from session B</description></interface>")

with connect() as a, connect() as b:
    print("A session", a.session_id, "B session", b.session_id)
    a.lock("candidate")
    print("A: lock candidate: ok")
    try:
        b.edit_config(target="candidate", config=EDIT)
    except RPCError as e:
        print("B: edit-config:", e.tag, "-", e.message)
    a.unlock("candidate")
    print("A: unlock candidate: ok")
    b.edit_config(target="candidate", config=EDIT)
    print("B: edit-config: ok")
    b.discard_changes()
CODE
block locks
on ctl 'python locks.py'

block rc-get
on ctl 'curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2'
block rc-patch
on ctl 'curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '"'"'{"ietf-interfaces:interface": [{"name": "eth2", "description": "to pc1, desk 4"}]}'"'"' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2'
on ctl 'curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2/description'
block rc-post
on ctl 'curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d '"'"'{"ietf-interfaces:interface": [{"name": "eth3", "type": "iana-if-type:ethernetCsmacd", "enabled": false}]}'"'"' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces'
block rc-delete
on ctl 'curl -si -n --cacert lab-ca.pem -X DELETE https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth3'
block rc-error
on ctl 'curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '"'"'{"ietf-interfaces:interface": [{"name": "eth2", "ietf-ip:ipv4": {"address": [{"ip": "192.0.2.99", "prefix-length": 33}]}}]}'"'"' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2'
block rc-root
on ctl 'curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf'
put restconf.py <<'CODE'
import requests

BASE = "https://nc1.example.net/restconf/data"
JSON = "application/yang-data+json"
http = requests.Session()
http.verify = "lab-ca.pem"
http.headers.update({"Accept": JSON, "Content-Type": JSON})

r = http.get(f"{BASE}/ietf-interfaces:interfaces/interface=eth1", timeout=10)
r.raise_for_status()
eth1 = r.json()["ietf-interfaces:interface"][0]
print(eth1["name"], eth1["description"], eth1["enabled"])

r = http.patch(f"{BASE}/ietf-interfaces:interfaces/interface=eth1", timeout=10,
               json={"ietf-interfaces:interface": [{"name": "eth1", "description": "uplink to core1"}]})
print("PATCH", r.status_code)
CODE
block rc-python
on ctl 'python restconf.py'
block rc-netconf-sees
on ctl 'python -c "from nc import connect, describe; print(describe(connect(), \"running\", \"eth2\"))"'
