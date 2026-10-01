#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The models are the files that ship with the tools: the IETF modules pyang
# 2.7.1 installs under /opt/netauto/share/yang/modules, FRR 8.4's own under
# /usr/share/yang, and OpenConfig's from openconfig/public at the commit lab.sh
# names. yanglint is libyang 2.1.30, Ubuntu's libyang-tools.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; three links in ana's home, ietf, iana and
# openconfig, to the directories above, so the commands stay short; and the
# files ana wrote (put below), whose contents the lesson shows.
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
IETF=/opt/netauto/share/yang/modules
lab exec ctl ana "ln -s $IETF/ietf ietf; ln -s $IETF/iana iana; ln -s /opt/labsrc/openconfig/release/models openconfig"

block ls
on ctl 'ls ietf | head -8; ls ietf | wc -l'
block tree-interfaces
on ctl 'pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang'
block source
on ctl 'grep -n -B2 -A10 "leaf prefix-length {" ietf/ietf-ip.yang | head -13'
block augment
on ctl 'pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang ietf/ietf-ip.yang --tree-path /interfaces/interface/ipv4'
block augment-source
on ctl 'grep -n -A3 "augment \"/if:interfaces/if:interface\" {" ietf/ietf-ip.yang | head -4'
block openconfig
on ctl 'pyang -f tree -p openconfig openconfig/interfaces/openconfig-interfaces.yang --tree-depth 5 | head -24'
block native
on ctl 'pyang -f tree -p /usr/share/yang /usr/share/yang/frr-interface.yang 2>/dev/null | head -12'
on ctl 'ls /usr/share/yang | grep -c "^frr-"'

put example-branches.yang <<'CODE'
module example-branches {
  yang-version 1.1;
  namespace "urn:example:branches";
  prefix br;

  import ietf-inet-types { prefix inet; }

  description "The branches of the lab's network, as data.";

  revision 2026-09-29 { description "First version."; }

  typedef branch-id {
    type uint16 { range "1..999"; }
    description "A branch's number, as the finance team assigns it.";
  }

  container branches {
    list branch {
      key "id";
      must "status != 'active' or dns-server" {
        error-message "an active branch needs at least one DNS server";
      }
      leaf id { type branch-id; }
      leaf name {
        type string { length "1..32"; }
        mandatory true;
      }
      leaf lan {
        type inet:ipv4-prefix;
        mandatory true;
      }
      leaf edge-router { type string; }
      leaf-list dns-server {
        type inet:ipv4-address;
        max-elements 2;
      }
      leaf status {
        type enumeration {
          enum planned;
          enum active;
          enum closed;
        }
        default planned;
      }
    }
  }
}
CODE
block module-check
on ctl 'pyang -p ietf example-branches.yang; echo "exit status $?"'
on ctl 'pyang -f tree -p ietf example-branches.yang'
block module-typo
on ctl "sed 's/type uint16 {/type unit16 {/' example-branches.yang > broken.yang"
on ctl 'pyang -p ietf broken.yang; echo "exit status $?"'

put branches.json <<'CODE'
{
  "example-branches:branches": {
    "branch": [
      {
        "id": 1,
        "name": "Branch 1",
        "lan": "203.0.113.0/26",
        "edge-router": "edge1",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 2,
        "name": "Branch 2",
        "lan": "203.0.113.64/26",
        "edge-router": "edge2",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 3,
        "name": "Branch 3",
        "lan": "203.0.113.128/26"
      }
    ]
  }
}
CODE
block data-ok
on ctl 'yanglint -p ietf example-branches.yang branches.json; echo "exit status $?"'
on ctl 'yanglint -f json -p ietf example-branches.yang branches.json | tail -9'
block data-range
on ctl "sed 's/\"id\": 3,/\"id\": 1000,/' branches.json > bad-id.json"
on ctl 'yanglint -p ietf example-branches.yang bad-id.json; echo "exit status $?"'
block data-prefix
on ctl "sed 's#203.0.113.128/26#203.0.113.128/33#' branches.json > bad-lan.json"
on ctl 'yanglint -p ietf example-branches.yang bad-lan.json; echo "exit status $?"'
block data-must
on ctl "python3 -c 'import json; d=json.load(open(\"branches.json\")); b=d[\"example-branches:branches\"][\"branch\"][2]; b[\"status\"]=\"active\"; json.dump(d, open(\"bad-dns.json\",\"w\"))'"
on ctl 'yanglint -p ietf example-branches.yang bad-dns.json; echo "exit status $?"'
block data-missing
on ctl "python3 -c 'import json; d=json.load(open(\"branches.json\")); del d[\"example-branches:branches\"][\"branch\"][1][\"name\"]; json.dump(d, open(\"bad-name.json\",\"w\"))'"
on ctl 'yanglint -p ietf example-branches.yang bad-name.json; echo "exit status $?"'

block device-models
on ctl 'curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-yang-library:yang-library | jq -r '"'"'.["ietf-yang-library:yang-library"]["module-set"][0].module[] | "\(.name) \(.revision)"'"'"' | sort'
block device-unknown
on ctl 'curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d @branches.json https://nc1.example.net/restconf/data'
