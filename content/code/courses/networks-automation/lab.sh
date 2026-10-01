#!/usr/bin/env bash
# The network every transcript in this course was recorded on, and the
# machine the automation runs from.
#
# IT IS ONE LINUX COMPUTER, the same trick as the networks course's lab.sh:
# each machine below is a network namespace with its own interfaces, routes and
# hostname, and its own copy of the directories a machine is told apart by. The
# cables are virtual Ethernet pairs plugged into bridges, and they carry no
# delay, so a time printed in a lesson is one computer talking to itself.
#
#   ctl       the automation host: ana's Python, Ansible and Git live here
#   core1     a router: FRR, SSH to its CLI, a REST API and a gNMI target
#   edge1     the same, at the edge of branch 1
#   edge2     the same, at the edge of branch 2
#   nc1       a device managed only through its model: NETCONF and RESTCONF
#   netbox    NetBox, the source of truth of lesson 12
#   tickets   the service desk the webhooks of lesson 7 open tickets in
#   pc1, pc2  one computer on each branch's LAN, to test the network from
#   sw1       an OpenFlow switch, Open vSwitch, for lesson 15
#   h1-h3     three computers plugged into sw1
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE. No vendor image runs here:
# the network operating systems people automate at work are licensed, and the
# one free image that has every API was out of reach from the machine this was
# recorded on. So the routers are built from open-source parts, and the parts
# that do not exist in open source were written for the lab, below, where
# anybody can read them:
#
#   real       FRR 8.4 (routing, the CLI, frr-reload), OpenSSH, Open vSwitch
#              3.3 with OS-Ken as its OpenFlow controller, Clixon
#              (NETCONF, RESTCONF and a CLI generated from YANG), NetBox,
#              Ansible and its frr.frr collection, and every Python library
#              ana imports: Netmiko, NAPALM, Nornir, ncclient, pygnmi, Jinja2.
#   the lab's  devapi (the routers' REST API and gNMI target, over FRR and the
#              kernel), napalm_frr (a NAPALM driver: NAPALM ships none for
#              FRR) and deskd (the service desk). Each is a few hundred lines
#              in this file and says in its header what it copies.
#
# The lessons say which is which wherever it matters to what the student sees.
#
# NOTHING HERE REACHES THE REAL INTERNET. Addresses are the ranges reserved for
# documentation (RFC 5737) and names end in example.net (RFC 2606).
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           tear it down and build it again
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'
#
# Recorded on Ubuntu 24.04. The packages are in need(); the Python libraries
# are pinned in PYLIBS and installed into /opt/netauto; Clixon and NetBox are
# built from the commits named beside them.
set -euo pipefail

LAB=/lab
TZ_LAB=America/Sao_Paulo
VENV=/opt/netauto
NETBOX=/opt/netbox

#        segment  host     iface address/prefix
LINKS="
mgmt     ctl      eth0 192.0.2.10/24
mgmt     core1    eth0 192.0.2.11/24
mgmt     edge1    eth0 192.0.2.12/24
mgmt     edge2    eth0 192.0.2.13/24
mgmt     nc1      eth0 192.0.2.21/24
mgmt     netbox   eth0 192.0.2.30/24
mgmt     tickets  eth0 192.0.2.40/24
mgmt     sw1      eth0 192.0.2.50/24
link1    core1    eth1 198.51.100.1/30
link1    edge1    eth1 198.51.100.2/30
link2    core1    eth2 198.51.100.5/30
link2    edge2    eth1 198.51.100.6/30
lan1     edge1    eth2 203.0.113.1/26
lan1     pc1      eth0 203.0.113.10/26
lan2     edge2    eth2 203.0.113.65/26
lan2     pc2      eth0 203.0.113.74/26
"
ROUTERS="core1 edge1 edge2"
# sw1's other ports are not on a bridge of ours: they are cabled straight to h1-h3
# and switched by Open vSwitch, in build_sdn.
SDN_HOSTS="h1 h2 h3"
HOSTS=$( (echo "$LINKS" | awk 'NF{print $2}'; printf '%s\n' $SDN_HOSTS) | sort -u)

PYLIBS="netmiko==4.8.0 napalm==5.2.0 nornir==3.6.0 nornir-netmiko==1.0.1 nornir-napalm==0.6.0
nornir-utils==0.3.0 nornir-netbox==0.3.0 ncclient==0.7.0 pygnmi==0.8.15 paramiko==5.0.0
Jinja2==3.1.6 pyang==2.7.1 requests==2.34.2 pytest==9.1.1 PyYAML==6.0.3 xmltodict==1.0.4
grpcio==1.84.0 pynetbox==7.8.0 ansible-pylibssh==1.4.0 os-ken==4.2.2"

need() {
  local missing=()
  for p in iproute2 iputils-ping traceroute frr frr-pythontools openssh-server ansible yamllint \
           git curl jq postgresql redis-server openssl python3-venv libyang-tools openvswitch-switch \
           libxml2-utils netcat-openbsd python3-paramiko; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  for c in clixon_backend gnmic "$VENV/bin/python" "$NETBOX/venv/bin/gunicorn"; do
    command -v "$c" >/dev/null || { echo "missing $c: run 'sudo bash lab.sh tools' first" >&2; exit 1; }
  done
}

# ------------------------------------------------------- the software, once
# What the machine needs besides Ubuntu's packages, each from a named version.
# Run once; `up` refuses to start without it.
tools() {
  useradd -m -s /bin/bash ana 2>/dev/null || true
  # Ubuntu's Ansible runs on Ubuntu's Python; an image whose python3 points
  # elsewhere breaks it, so python3 is the distribution's 3.12.
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 >/dev/null
  update-alternatives --set python3 /usr/bin/python3.12
  usermod -aG frrvty ana    # frr-reload.py reads /etc/frr/vtysh.conf on ctl
  [ -x "$VENV/bin/python" ] || /usr/bin/python3.12 -m venv "$VENV"
  # shellcheck disable=SC2086
  "$VENV/bin/pip" install -q $PYLIBS
  mkdir -p "$VENV/lib/python3.12/site-packages/napalm_frr"
  write_napalm_frr > "$VENV/lib/python3.12/site-packages/napalm_frr/__init__.py"
  mkdir -p /opt/labsrc
  if ! command -v clixon_backend >/dev/null; then   # CLIgen and Clixon, 2026-09-25
    apt-get install -y -qq flex bison libnghttp2-dev libssl-dev libcurl4-openssl-dev
    git clone -q https://github.com/clicon/cligen.git /opt/labsrc/cligen
    git -C /opt/labsrc/cligen checkout -q 9fd27a8
    git clone -q https://github.com/clicon/clixon.git /opt/labsrc/clixon
    git -C /opt/labsrc/clixon checkout -q 9817840
    (cd /opt/labsrc/cligen && ./configure -q && make -s -j4 && make -s install)
    ldconfig
    (cd /opt/labsrc/clixon && ./configure -q --with-restconf=native && make -s -j4 && make -s install)
    ldconfig
  fi
  if ! command -v gnmic >/dev/null; then            # gnmic v0.42.0
    git clone -q --depth 1 --branch v0.42.0 https://github.com/openconfig/gnmic.git /opt/labsrc/gnmic
    (cd /opt/labsrc/gnmic && go build -o /usr/local/bin/gnmic .)
  fi
  if [ ! -d /opt/labsrc/openconfig ]; then          # OpenConfig's published models, 806f013
    git clone -q --filter=blob:none --sparse https://github.com/openconfig/public.git /opt/labsrc/openconfig
    git -C /opt/labsrc/openconfig checkout -q 806f013
    git -C /opt/labsrc/openconfig sparse-checkout set --no-cone '/release/models/interfaces/*' \
      '/release/models/types/*' /release/models/openconfig-extensions.yang \
      /release/models/system/openconfig-system.yang \
      /release/models/optical-transport/openconfig-transport-types.yang \
      /release/models/platform/openconfig-platform-types.yang
  fi
  if [ ! -x "$NETBOX/venv/bin/gunicorn" ]; then     # NetBox v4.6.10
    apt-get install -y -qq libpq-dev python3.12-dev
    git clone -q --depth 1 --branch v4.6.10 https://github.com/netbox-community/netbox.git "$NETBOX"
    /usr/bin/python3.12 -m venv "$NETBOX/venv"
    "$NETBOX/venv/bin/pip" install -q -r "$NETBOX/requirements.txt"
  fi
}

mac() {  # 52:54:00 and the last three bytes of the address, so a MAC says whose it is
  local a=${1%/*}; IFS=. read -r _ b c d <<< "$a"
  printf '52:54:00:%02x:%02x:%02x' "$b" "$c" "$d"
}

# ------------------------------------------------------------------ the wires
build_net() {
  ip netns add wire
  ip -n wire link set lo up
  for seg in $(echo "$LINKS" | awk 'NF{print $1}' | sort -u); do
    ip -n wire link add "br-$seg" type bridge
    ip -n wire link set "br-$seg" up
  done
  for h in $HOSTS; do
    ip netns add "$h"
    ip -n "$h" link set lo up
    [ -e /proc/sys/net/ipv6 ] && ip netns exec "$h" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    ip netns exec "$h" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    n=$((n + 1))
    ip link add "v$n-$h" type veth peer name "lab-tmp$n"
    ip link set "lab-tmp$n" netns "$h"
    ip -n "$h" link set "lab-tmp$n" name "$ifc"
    ip -n "$h" link set "$ifc" address "$(mac "$addr")"
    # A router's interfaces are addressed by FRR, from its configuration, the
    # way a router's are. Everything else is addressed here.
    case " $ROUTERS " in *" $h "*) [ "$ifc" = eth0 ] && ip -n "$h" addr add "$addr" dev "$ifc" ;;
                         *) ip -n "$h" addr add "$addr" dev "$ifc" ;; esac
    ip -n "$h" link set "$ifc" up
    ip link set "v$n-$h" netns wire
    ip -n wire link set "v$n-$h" master "br-$seg"
    ip -n wire link set "v$n-$h" up
  done
  ip -n pc1 route add default via 203.0.113.1
  ip -n pc2 route add default via 203.0.113.65
  for r in $ROUTERS; do ip netns exec "$r" sysctl -qw net.ipv4.ip_forward=1; done
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="home etc/frr run/frr var/log/frr etc/ssh etc/devapi etc/clixon var/clixon etc/deskd var/lib/deskd
         etc/openvswitch run/openvswitch var/log/openvswitch"
overlay() {
  local h=$1 p
  for p in $OVERLAY; do
    [ -e "$LAB/$h/$p" ] && { [ -e "/$p" ] || mkdir -p "/$p"; } && mount --bind "$LAB/$h/$p" "/$p"
  done
  return 0
}

exec_on() {  # exec_on HOST USER COMMAND
  local h=$1 u=$2 c=$3
  ip netns exec "$h" unshare --uts bash -c '
    '"$(declare -f overlay)"'; LAB='"$LAB"'; OVERLAY="'"$OVERLAY"'"
    hostname "$1"; overlay "$1"
    P=/opt/netauto/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=$P TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=$P TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

NAMES="
192.0.2.10 ctl
192.0.2.11 core1
192.0.2.12 edge1
192.0.2.13 edge2
192.0.2.21 nc1
192.0.2.30 netbox
192.0.2.40 tickets
192.0.2.50 sw1
"
hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana"
    {
      printf '127.0.0.1 localhost\n'
      grep -qw "$h" <<< "$NAMES" || printf '127.0.1.1 %s\n' "$h"
      echo "$NAMES" | awk 'NF{printf "%s %s.example.net %s\n", $1, $2, $2}'
    } > "/etc/netns/$h/hosts"
    : > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    cp -a /etc/skel/. "$LAB/$h/home/ana/"
    chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
  done
}

# ------------------------------------------------------------------ the routers
# Three routers joined by two point-to-point links, OSPF between them, and a
# branch LAN behind each edge. Their management port, eth0, is addressed by the
# lab like a management port; everything else comes from frr.conf.
loopback() { case $1 in core1) echo 203.0.113.251 ;; edge1) echo 203.0.113.252 ;; edge2) echo 203.0.113.253 ;; esac; }

frr_conf() {  # frr_conf ROUTER: the configuration it boots with
  local r=$1 lo; lo=$(loopback "$r")
  cat <<C
frr version 8.4.4
frr defaults traditional
hostname $r
log file /var/log/frr/frr.log informational
service integrated-vtysh-config
!
C
  case $r in
    core1) cat <<'C'
interface eth1
 description link to edge1
 ip address 198.51.100.1/30
 ip ospf network point-to-point
exit
!
interface eth2
 description link to edge2
 ip address 198.51.100.5/30
 ip ospf network point-to-point
exit
!
C
    ;;
    edge1|edge2)
      local up lan
      [ "$r" = edge1 ] && { up=198.51.100.2/30; lan=203.0.113.1/26; } || { up=198.51.100.6/30; lan=203.0.113.65/26; }
      cat <<C
interface eth1
 description uplink to core1
 ip address $up
 ip ospf network point-to-point
exit
!
interface eth2
 description branch LAN
 ip address $lan
 ip ospf passive
exit
!
C
    ;;
  esac
  cat <<C
interface lo
 ip address $lo/32
exit
!
router ospf
 ospf router-id $lo
 redistribute connected
C
  case $r in
    core1) printf ' network 198.51.100.0/30 area 0\n network 198.51.100.4/30 area 0\n' ;;
    edge1) printf ' network 198.51.100.0/30 area 0\n network 203.0.113.0/26 area 0\n' ;;
    edge2) printf ' network 198.51.100.4/30 area 0\n network 203.0.113.64/26 area 0\n' ;;
  esac
  printf 'exit\n!\nline vty\n exec-timeout 30 0\nexit\n!\nend\n'
}

build_frr() {
  for r in $ROUTERS; do
    local d="$LAB/$r/etc/frr"
    mkdir -p "$d" "$LAB/$r/run/frr" "$LAB/$r/var/log/frr"
    sed -e 's/^ospfd=no/ospfd=yes/' -e 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons > "$d/daemons"
    frr_conf "$r" > "$d/frr.conf"
    printf 'service integrated-vtysh-config\n' > "$d/vtysh.conf"
    chown -R frr:frr "$d" "$LAB/$r/run/frr" "$LAB/$r/var/log/frr"
    chmod 640 "$d/frr.conf"
    chgrp frrvty "$d/vtysh.conf" "$d"; chmod 775 "$d"
    exec_on "$r" root '/usr/lib/frr/frrinit.sh start' >/dev/null
  done
}

# ---------------------------------------------------------------- SSH to them
# netops is the account automation logs in with. Its shell is vtysh, so an SSH
# session lands in the router's CLI and not in Linux, as it would on a router.
NETOPS_PASSWORD='lab-netops-26'
DEVAPI_READONLY_PASSWORD='lab-audit-26'
build_ssh() {
  id netops >/dev/null 2>&1 || useradd -M -d /home/netops -s /usr/bin/vtysh -G frrvty netops
  echo "netops:$NETOPS_PASSWORD" | chpasswd
  grep -qx /usr/bin/vtysh /etc/shells || echo /usr/bin/vtysh >> /etc/shells
  mkdir -p /run/sshd
  # ana's key, made once on ctl and trusted by every router
  local k="$LAB/ctl/home/ana/.ssh"
  mkdir -p "$k"
  [ -f "$k/id_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -C ana@ctl -f "$k/id_ed25519"
  : > "$k/known_hosts"
  for h in $ROUTERS nc1; do
    local s="$LAB/$h/etc/ssh" a
    a=$(awk -v h="$h" '$2==h{print $1}' <<< "$NAMES")
    mkdir -p "$s" "$LAB/$h/home/netops/.ssh"
    [ -f "$s/ssh_host_ed25519_key" ] || ssh-keygen -q -t ed25519 -N '' -C "root@$h" -f "$s/ssh_host_ed25519_key"
    [ -f "$s/ssh_host_rsa_key" ] || ssh-keygen -q -t rsa -b 3072 -N '' -C "root@$h" -f "$s/ssh_host_rsa_key"
    cat > "$s/sshd_config" <<C
ListenAddress $a
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
PasswordAuthentication yes
KbdInteractiveAuthentication no
UsePAM no
PrintLastLog no
PrintMotd no
AllowUsers netops
PidFile /run/sshd-$h.pid
C
    [ "$h" = nc1 ] && cat >> "$s/sshd_config" <<C
Port 22
Port 830
Subsystem netconf /usr/local/bin/clixon_netconf -f /etc/clixon/nc1.xml
C
    cp "$k/id_ed25519.pub" "$LAB/$h/home/netops/.ssh/authorized_keys"
    chown -R netops:netops "$LAB/$h/home/netops"; chmod 700 "$LAB/$h/home/netops/.ssh"
    printf '%s,%s.example.net,%s %s\n' "$h" "$h" "$a" "$(cut -d' ' -f1,2 "$s/ssh_host_ed25519_key.pub")" >> "$k/known_hosts"
    printf '%s,%s.example.net,%s %s\n' "$h" "$h" "$a" "$(cut -d' ' -f1,2 "$s/ssh_host_rsa_key.pub")" >> "$k/known_hosts"
    # On nc1 netops has an ordinary shell: sshd runs the NETCONF subsystem
    # through it, and vtysh would take it for a command it does not know.
    if [ "$h" = nc1 ]; then
      sed 's#^\(netops:.*:\)/usr/bin/vtysh$#\1/bin/sh#' /etc/passwd > /etc/netns/nc1/passwd
      cp /etc/shadow /etc/group /etc/netns/nc1/
    fi
    # nc1's sshd starts with Clixon, in build_nc1: the NETCONF subsystem needs
    # /etc/clixon to exist when sshd does, or the mount is not there to inherit.
    [ "$h" = nc1 ] || exec_on "$h" root '/usr/sbin/sshd -f /etc/ssh/sshd_config'
  done
  chown -R ana:ana "$k"; chmod 700 "$k"
  # The passwords ana's programs read, one file each, readable by her alone:
  # a secret in a file with 0600 is the lab's stand-in for a vault.
  printf '%s\n' "$NETOPS_PASSWORD" > "$LAB/ctl/home/ana/.netops-password"
  printf '%s\n' "$DEVAPI_READONLY_PASSWORD" > "$LAB/ctl/home/ana/.audit-password"
  chown ana:ana "$LAB/ctl/home/ana/".*-password; chmod 600 "$LAB/ctl/home/ana/".*-password
  # and a .netrc for nc1, whose RESTCONF takes HTTP Basic: curl -n reads it, and
  # so does requests. Only nc1: requests lets a .netrc entry replace the Bearer
  # token a session sends, so an entry for a router would break lesson 2.
  printf 'machine nc1.example.net login netops password %s\n' "$NETOPS_PASSWORD" > "$LAB/ctl/home/ana/.netrc"
  chown ana:ana "$LAB/ctl/home/ana/.netrc"; chmod 600 "$LAB/ctl/home/ana/.netrc"
}

# ------------------------------------------------------ the lab's certificates
# One certificate authority for the whole lab, and a certificate per device
# signed by it. ana's programs verify against it and never turn checking off:
# /home/ana/lab-ca.pem on ctl is the file they name.
build_ca() {
  local d=$LAB/ca
  mkdir -p "$d"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/O=Lab/CN=Lab Root CA" \
    -keyout "$d/ca.key" -out "$d/ca.pem" 2>/dev/null
  for h in $ROUTERS nc1 netbox tickets; do
    local a; a=$(awk -v h="$h" '$2==h{print $1}' <<< "$NAMES")
    openssl req -newkey rsa:2048 -nodes -subj "/CN=$h.example.net" \
      -keyout "$d/$h.key" -out "$d/$h.csr" 2>/dev/null
    printf 'subjectAltName=DNS:%s.example.net,DNS:%s,IP:%s\nextendedKeyUsage=serverAuth\n' "$h" "$h" "$a" > "$d/$h.ext"
    openssl x509 -req -in "$d/$h.csr" -CA "$d/ca.pem" -CAkey "$d/ca.key" -CAcreateserial \
      -days 825 -extfile "$d/$h.ext" -out "$d/$h.pem" 2>/dev/null
  done
  cp "$d/ca.pem" "$LAB/ctl/home/ana/lab-ca.pem"; chown ana:ana "$LAB/ctl/home/ana/lab-ca.pem"
}

# ---------------------------------------------------- the routers' own API
build_devapi() {
  mkdir -p /opt/lab
  write_devapi > /opt/lab/devapi.py
  for r in $ROUTERS; do
    local a; a=$(awk -v h="$r" '$2==h{print $1}' <<< "$NAMES")
    mkdir -p "$LAB/$r/etc/devapi"
    cp "$LAB/ca/$r.pem" "$LAB/ca/$r.key" "$LAB/$r/etc/devapi/"
    cat > "$LAB/$r/etc/devapi/devapi.json" <<C
{"hostname": "$r", "address": "$a",
 "cert": "/etc/devapi/$r.pem", "key": "/etc/devapi/$r.key",
 "users": {"netops": {"password": "$NETOPS_PASSWORD", "role": "read-write"},
           "audit":  {"password": "$DEVAPI_READONLY_PASSWORD", "role": "read-only"}}}
C
    chmod 600 "$LAB/$r/etc/devapi/"*
    exec_on "$r" root "setsid $VENV/bin/python /opt/lab/devapi.py </dev/null >>/var/log/devapi.err 2>&1 &"
  done
}

write_devapi() {
cat <<'DEVAPI'
#!/opt/netauto/bin/python
"""devapi: the management API of the lab's routers, written for this course.

A router you buy answers on a REST API and a gNMI port. FRR answers on neither,
so this program does, in front of it: every read comes from FRR (vtysh ... json)
or the kernel (/sys/class/net), and every write is a vtysh command, the same one
a person would type. Nothing is kept here that FRR does not also hold, apart
from sessions, webhook subscriptions and the rate limiter.

What it copies from real equipment, so the lessons can be about the pattern
rather than about this program:
  REST  a login that returns a bearer token which expires; JSON everywhere;
        GET/POST/PUT/PATCH/DELETE with the status codes RFC 9110 gives them;
        offset pagination with a `next` link, as NetBox and many controllers
        do; 429 with Retry-After when a client asks too fast; webhooks signed
        with HMAC-SHA256.
  gNMI  the gNMI 0.8 service (Capabilities, Get, Set, Subscribe) over TLS, with
        the credentials in the call's metadata, on port 9339, serving a subset
        of openconfig-interfaces and openconfig-system.

Configuration: /etc/devapi/devapi.json. Run as root inside the router.
"""
import base64
import hashlib
import hmac
import ipaddress
import json
import os
import re
import secrets
import socket
import ssl
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
from concurrent import futures
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import grpc
from pygnmi.spec.v080 import gnmi_pb2, gnmi_pb2_grpc

CONF = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "/etc/devapi/devapi.json"))
HOST = CONF["hostname"]
USERS = CONF["users"]              # name -> {"password": ..., "role": "read-write"|"read-only"}
TOKEN_LIFE = CONF.get("token_seconds", 900)
RATE = CONF.get("rate", [30, 10])  # at most RATE[0] requests per RATE[1] seconds, per token
STARTED = time.time()
LOCK = threading.Lock()


# ------------------------------------------------------------------ FRR itself
def vtysh(*commands):
    args = ["vtysh"]
    for c in commands:
        args += ["-c", c]
    r = subprocess.run(args, capture_output=True, text=True)
    return r.stdout + r.stderr


def vtysh_json(command):
    return json.loads(vtysh(command) or "{}")


def configure(lines):
    """Apply configuration lines to the running configuration, as a person would."""
    out = vtysh("configure terminal", *lines, "end")
    bad = [l for l in out.splitlines() if l.startswith("%")]
    if bad:
        raise ValueError("; ".join(bad))


def sysfs(ifname, name):
    try:
        return open(f"/sys/class/net/{ifname}/{name}").read().strip()
    except OSError:
        return None


def interfaces():
    raw = vtysh_json("show interface json")
    out = []
    for name in sorted(raw):
        i = raw[name]
        oper = sysfs(name, "operstate")
        if name == "lo":
            oper = "up"
        out.append({
            "name": name,
            "description": i.get("description", ""),
            "enabled": i.get("administrativeStatus") == "up",
            "oper_status": "up" if oper in ("up", "unknown") else "down",
            "mtu": i.get("mtu"),
            "mac_address": i.get("hardwareAddress", ""),
            "addresses": [a["address"] for a in i.get("ipAddresses", [])],
        })
    return out


def counters(ifname):
    s = lambda n: int(sysfs(ifname, "statistics/" + n) or 0)
    return {"in-octets": s("rx_bytes"), "out-octets": s("tx_bytes"),
            "in-pkts": s("rx_packets"), "out-pkts": s("tx_packets"),
            "in-errors": s("rx_errors"), "out-errors": s("tx_errors"),
            "in-discards": s("rx_dropped"), "out-discards": s("tx_dropped")}


def routes():
    raw = vtysh_json("show ip route json")
    out = []
    for prefix in sorted(raw, key=lambda p: ipaddress.ip_network(p)):
        for r in raw[prefix]:
            out.append({
                "prefix": prefix,
                "protocol": r.get("protocol"),
                "selected": bool(r.get("selected")),
                "distance": r.get("distance"),
                "metric": r.get("metric"),
                "next_hops": [{k: v for k, v in (("ip", n.get("ip")), ("interface", n.get("interfaceName"))) if v}
                              for n in r.get("nexthops", [])],
            })
    return out


STATIC = re.compile(r"^ip route (\S+) (\S+)(?: (\d+))?$")


def static_routes():
    out = []
    for line in vtysh("show running-config").splitlines():
        m = STATIC.match(line.strip())
        if m:
            out.append({"prefix": m[1], "next_hop": m[2], "distance": int(m[3] or 1)})
    return out


def version():
    first = vtysh("show version").splitlines()[0]
    return first.split(" (")[0]


# ------------------------------------------------------------------- webhooks
HOOKS = {}      # id -> subscription
DELIVERIES = []


def sign(secret, body):
    return "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()


def deliver(hook, event):
    body = json.dumps(event, separators=(",", ":")).encode()
    for attempt, wait in enumerate((0, 1, 2, 4), start=1):
        time.sleep(wait)
        req = urllib.request.Request(hook["url"], data=body, method="POST", headers={
            "Content-Type": "application/json",
            "User-Agent": "devapi/1.0",
            "X-Devapi-Event": event["event"],
            "X-Devapi-Delivery": event["id"],
            "X-Devapi-Signature": sign(hook["secret"], body)})
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                status = r.status
        except urllib.error.HTTPError as e:
            status = e.code
        except OSError:
            status = None
        with LOCK:
            DELIVERIES.append({"hook": hook["id"], "delivery": event["id"], "attempt": attempt,
                               "status": status, "time": now()})
        if status is not None and 200 <= status < 300:
            return


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def watch_links():
    """Turn a change of an interface's operational state into an event."""
    last = {}
    n = 0
    while True:
        for i in interfaces():
            before = last.get(i["name"])
            last[i["name"]] = i["oper_status"]
            if before is None or before == i["oper_status"]:
                continue
            n += 1
            event = {"id": f"{HOST}-{int(STARTED)}-{n}", "event": "interface." + i["oper_status"],
                     "device": HOST, "interface": i["name"], "description": i["description"],
                     "time": now()}
            for hook in list(HOOKS.values()):
                if event["event"] in hook["events"]:
                    threading.Thread(target=deliver, args=(hook, event), daemon=True).start()
        time.sleep(0.5)


# ------------------------------------------------------------------------ REST
SESSIONS = {}   # token -> (user, expires)
BUCKETS = {}    # token -> [request times]


class Problem(Exception):
    def __init__(self, status, message, **extra):
        self.status, self.message, self.extra = status, message, extra


def page(items, query, path):
    try:
        limit = int(query.get("limit", ["50"])[0])
        offset = int(query.get("offset", ["0"])[0])
    except ValueError:
        raise Problem(400, "limit and offset are whole numbers")
    if not 1 <= limit <= 100 or offset < 0:
        raise Problem(400, "limit is between 1 and 100, and offset is 0 or more")
    base = f"https://{HOST}.example.net{path}"
    keep = {k: v[0] for k, v in query.items() if k not in ("limit", "offset")}

    def link(o):
        return base + "?" + urllib.parse.urlencode({**keep, "limit": limit, "offset": o})

    return {"count": len(items),
            "next": link(offset + limit) if offset + limit < len(items) else None,
            "previous": link(max(offset - limit, 0)) if offset > 0 else None,
            "results": items[offset:offset + limit]}


class Api(BaseHTTPRequestHandler):
    def version_string(self):
        return "devapi/1.0"
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        with open("/var/log/devapi.log", "a") as f:
            f.write("%s %s %s\n" % (now(), self.address_string(), fmt % args))

    # --- plumbing
    def send(self, status, body=None, headers=()):
        data = b"" if body is None else (json.dumps(body, indent=2) + "\n").encode()
        self.send_response(status)
        if body is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        if not raw:
            return {}
        if not (self.headers.get("Content-Type") or "").startswith("application/json"):
            raise Problem(415, "send the body as application/json")
        try:
            data = json.loads(raw)
        except ValueError:
            raise Problem(400, "the body is not valid JSON")
        if not isinstance(data, dict):
            raise Problem(400, "the body is a JSON object")
        return data

    def who(self):
        auth = self.headers.get("Authorization", "")
        token = auth[7:] if auth.startswith("Bearer ") else None
        s = SESSIONS.get(token)
        if not s:
            raise Problem(401, "missing or unknown token: log in at /api/v1/auth/login")
        if s[1] < time.time():
            del SESSIONS[token]
            raise Problem(401, "the token has expired: log in again")
        with LOCK:
            times = [t for t in BUCKETS.get(token, []) if t > time.time() - RATE[1]]
            if len(times) >= RATE[0]:
                BUCKETS[token] = times
                raise Problem(429, f"more than {RATE[0]} requests in {RATE[1]} seconds",
                              retry=int(times[0] + RATE[1] - time.time()) + 1)
            times.append(time.time())
            BUCKETS[token] = times
        return s[0]

    def writer(self):
        user = self.who()
        if USERS[user]["role"] != "read-write":
            raise Problem(403, f"{user} may read and may not change anything")
        return user

    def handle_any(self, verb):
        url = urllib.parse.urlsplit(self.path)
        path = url.path.rstrip("/") or "/"
        query = urllib.parse.parse_qs(url.query)
        try:
            for pattern, handlers in ROUTES:
                m = re.fullmatch(pattern, path)
                if m:
                    h = handlers.get(verb)
                    if not h:
                        raise Problem(405, f"{verb} is not allowed on {path}",
                                      allow=", ".join(sorted(handlers)))
                    return h(self, query, path, *[urllib.parse.unquote(g) for g in m.groups()])
            raise Problem(404, f"nothing at {path}")
        except Problem as p:
            headers = []
            if p.status == 401:
                headers.append(("WWW-Authenticate", 'Bearer realm="devapi"'))
            if p.status == 429:
                headers.append(("Retry-After", str(p.extra["retry"])))
            if p.status == 405:
                headers.append(("Allow", p.extra["allow"]))
            body = {"error": p.message}
            body.update({k: v for k, v in p.extra.items() if k not in ("retry", "allow")})
            self.send(p.status, body, headers)

    def do_GET(self): self.handle_any("GET")
    def do_POST(self): self.handle_any("POST")
    def do_PUT(self): self.handle_any("PUT")
    def do_PATCH(self): self.handle_any("PATCH")
    def do_DELETE(self): self.handle_any("DELETE")

    # --- resources
    def login(self, q, path):
        b = self.body()
        u = USERS.get(b.get("username"))
        if not u or not hmac.compare_digest(u["password"], str(b.get("password", ""))):
            raise Problem(401, "wrong username or password")
        token = secrets.token_hex(16)
        SESSIONS[token] = (b["username"], time.time() + TOKEN_LIFE)
        self.send(200, {"token": token, "token_type": "Bearer", "expires_in": TOKEN_LIFE})

    def logout(self, q, path):
        self.who()
        SESSIONS.pop(self.headers["Authorization"][7:], None)
        self.send(204)

    def system(self, q, path):
        self.who()
        self.send(200, {"hostname": HOST, "software": version(),
                        "uptime_seconds": int(time.time() - STARTED),
                        "management_address": CONF["address"]})

    def list_interfaces(self, q, path):
        self.who()
        self.send(200, page(interfaces(), q, path))

    def get_interface(self, q, path, name):
        self.who()
        for i in interfaces():
            if i["name"] == name:
                return self.send(200, i)
        raise Problem(404, f"no interface {name}")

    def patch_interface(self, q, path, name):
        self.writer()
        b = self.body()
        if name not in [i["name"] for i in interfaces()]:
            raise Problem(404, f"no interface {name}")
        unknown = set(b) - {"description", "enabled"}
        if unknown:
            raise Problem(422, "only description and enabled can be changed",
                          fields=sorted(unknown))
        lines = [f"interface {name}"]
        if "description" in b:
            d = b["description"]
            if not isinstance(d, str) or len(d) > 80:
                raise Problem(422, "description is text of at most 80 characters")
            lines.append(f"description {d}" if d else "no description")
        if "enabled" in b:
            if not isinstance(b["enabled"], bool):
                raise Problem(422, "enabled is true or false")
            lines.append("no shutdown" if b["enabled"] else "shutdown")
        configure(lines)
        self.get_interface(q, path, name)

    def list_routes(self, q, path):
        self.who()
        items = routes()
        if "protocol" in q:
            items = [r for r in items if r["protocol"] == q["protocol"][0]]
        self.send(200, page(items, q, path))

    def list_static(self, q, path):
        self.who()
        self.send(200, page(static_routes(), q, path))

    def check_static(self, b, prefix=None):
        prefix = prefix or b.get("prefix")
        try:
            net = ipaddress.ip_network(str(prefix))
        except ValueError:
            raise Problem(422, f"{prefix!r} is not a network in CIDR form, such as 192.0.2.0/24",
                          field="prefix")
        if str(net) != prefix:
            raise Problem(422, f"{prefix} has host bits set: the network is {net}", field="prefix")
        try:
            ipaddress.ip_address(str(b.get("next_hop")))
        except ValueError:
            raise Problem(422, f"{b.get('next_hop')!r} is not an IP address", field="next_hop")
        d = b.get("distance", 1)
        if not isinstance(d, int) or not 1 <= d <= 255:
            raise Problem(422, "distance is a whole number from 1 to 255", field="distance")
        return {"prefix": prefix, "next_hop": b["next_hop"], "distance": d}

    def route_line(self, r):
        return f"ip route {r['prefix']} {r['next_hop']}" + (f" {r['distance']}" if r["distance"] != 1 else "")

    def create_static(self, q, path):
        self.writer()
        r = self.check_static(self.body())
        if any(s["prefix"] == r["prefix"] for s in static_routes()):
            raise Problem(409, f"a static route to {r['prefix']} already exists",
                          existing=f"{path}/{urllib.parse.quote(r['prefix'], safe='')}")
        configure([self.route_line(r)])
        self.send(201, r, [("Location", f"{path}/{urllib.parse.quote(r['prefix'], safe='')}")])

    def find_static(self, prefix):
        for s in static_routes():
            if s["prefix"] == prefix:
                return s
        return None

    def get_static(self, q, path, prefix):
        self.who()
        s = self.find_static(prefix)
        if not s:
            raise Problem(404, f"no static route to {prefix}")
        self.send(200, s)

    def put_static(self, q, path, prefix):
        self.writer()
        r = self.check_static(self.body(), prefix)
        old = self.find_static(prefix)
        if old == r:
            return self.send(200, r)
        lines = ["no " + self.route_line(old)] if old else []
        configure(lines + [self.route_line(r)])
        self.send(200 if old else 201, r)

    def delete_static(self, q, path, prefix):
        self.writer()
        old = self.find_static(prefix)
        if not old:
            raise Problem(404, f"no static route to {prefix}")
        configure(["no " + self.route_line(old)])
        self.send(204)

    def get_config(self, q, path):
        self.who()
        self.send(200, {"format": "cli", "text": vtysh("show running-config")})

    def save_config(self, q, path):
        self.writer()
        out = vtysh("write memory")
        self.send(200, {"saved": "[OK]" in out})

    def list_hooks(self, q, path):
        self.who()
        self.send(200, page(list(HOOKS.values()), q, path))

    def create_hook(self, q, path):
        self.writer()
        b = self.body()
        u = urllib.parse.urlsplit(str(b.get("url", "")))
        if u.scheme not in ("http", "https") or not u.netloc:
            raise Problem(422, "url is an http or https address", field="url")
        events = b.get("events") or []
        known = {"interface.up", "interface.down"}
        if not events or set(events) - known:
            raise Problem(422, "events is a list drawn from " + ", ".join(sorted(known)), field="events")
        if not isinstance(b.get("secret"), str) or len(b["secret"]) < 16:
            raise Problem(422, "secret is text of at least 16 characters", field="secret")
        hid = "wh-" + secrets.token_hex(4)
        HOOKS[hid] = {"id": hid, "url": b["url"], "events": events, "secret": b["secret"]}
        self.send(201, {k: v for k, v in HOOKS[hid].items() if k != "secret"},
                  [("Location", f"{path}/{hid}")])

    def delete_hook(self, q, path, hid):
        self.writer()
        if not HOOKS.pop(hid, None):
            raise Problem(404, f"no webhook {hid}")
        self.send(204)

    def list_deliveries(self, q, path, hid):
        self.who()
        with LOCK:
            items = [d for d in DELIVERIES if d["hook"] == hid]
        self.send(200, page(items, q, path))


A = Api
ROUTES = [
    (r"/api/v1/auth/login", {"POST": A.login}),
    (r"/api/v1/auth/logout", {"POST": A.logout}),
    (r"/api/v1/system", {"GET": A.system}),
    (r"/api/v1/interfaces", {"GET": A.list_interfaces}),
    (r"/api/v1/interfaces/([^/]+)", {"GET": A.get_interface, "PATCH": A.patch_interface}),
    (r"/api/v1/routes", {"GET": A.list_routes}),
    (r"/api/v1/static-routes", {"GET": A.list_static, "POST": A.create_static}),
    (r"/api/v1/static-routes/([^/]+)", {"GET": A.get_static, "PUT": A.put_static,
                                         "DELETE": A.delete_static}),
    (r"/api/v1/config", {"GET": A.get_config}),
    (r"/api/v1/config/save", {"POST": A.save_config}),
    (r"/api/v1/webhooks", {"GET": A.list_hooks, "POST": A.create_hook}),
    (r"/api/v1/webhooks/([^/]+)", {"DELETE": A.delete_hook}),
    (r"/api/v1/webhooks/([^/]+)/deliveries", {"GET": A.list_deliveries}),
]


# ------------------------------------------------------------------------ gNMI
# The versions of the published models this subset is shaped like: the ones in
# openconfig/public at the commit lab.sh names (release/models).
MODELS = [("openconfig-interfaces", "OpenConfig working group", "3.11.0"),
          ("openconfig-system", "OpenConfig working group", "3.3.0")]


def state_tree():
    """The part of openconfig-interfaces and openconfig-system this device serves."""
    tree = {"interfaces": {"interface": {}}, "system": {"state": {
        "hostname": HOST, "boot-time": int(STARTED * 1e9),
        "current-datetime": datetime.now().astimezone().isoformat(timespec="seconds")}}}
    for i in interfaces():
        tree["interfaces"]["interface"][i["name"]] = {
            "name": i["name"],
            "config": {"name": i["name"], "description": i["description"],
                       "enabled": i["enabled"], "mtu": i["mtu"]},
            "state": {"name": i["name"], "description": i["description"],
                      "enabled": i["enabled"], "mtu": i["mtu"],
                      "admin-status": "UP" if i["enabled"] else "DOWN",
                      "oper-status": i["oper_status"].upper(),
                      "counters": counters(i["name"])},
        }
    return tree


def elems(path):
    return [(e.name, dict(e.key)) for e in path.elem]


def join(prefix, path):
    p = gnmi_pb2.Path()
    p.elem.extend(list(prefix.elem) + list(path.elem))
    return p


def resolve(tree, es, done=()):
    """Walk the tree along the path; yield (concrete elems, value) for every match."""
    if not es:
        yield list(done), tree
        return
    (name, keys), rest = es[0], es[1:]
    if not isinstance(tree, dict) or name not in tree:
        return
    node = tree[name]
    if name == "interface":
        for key, entry in node.items():
            want = keys.get("name", "*")
            if want in ("*", key):
                yield from resolve(entry, rest, done + ((name, {"name": key}),))
    else:
        yield from resolve(node, rest, done + ((name, keys),))


def to_path(es):
    p = gnmi_pb2.Path()
    for name, keys in es:
        e = p.elem.add()
        e.name = name
        for k, v in keys.items():
            e.key[k] = v
    return p


def typed(v, encoding):
    if isinstance(v, dict):
        data = json.dumps(v).encode()
        return gnmi_pb2.TypedValue(json_ietf_val=data) if encoding == gnmi_pb2.JSON_IETF \
            else gnmi_pb2.TypedValue(json_val=data)
    if isinstance(v, bool):
        return gnmi_pb2.TypedValue(bool_val=v)
    if isinstance(v, int):
        return gnmi_pb2.TypedValue(uint_val=v)
    return gnmi_pb2.TypedValue(string_val=str(v))


def leaves(es, v):
    if isinstance(v, dict):
        for k, sub in v.items():
            if k == "interface":
                for key, entry in sub.items():
                    yield from leaves(es + [(k, {"name": key})], entry)
            else:
                yield from leaves(es + [(k, {})], sub)
    else:
        yield es, v


def authorised(context, write=False):
    md = dict(context.invocation_metadata())
    u = USERS.get(md.get("username"))
    if not u or not hmac.compare_digest(u["password"], md.get("password", "")):
        context.abort(grpc.StatusCode.UNAUTHENTICATED, "wrong or missing username and password")
    if write and u["role"] != "read-write":
        context.abort(grpc.StatusCode.PERMISSION_DENIED, f"{md['username']} may not change anything")


class Gnmi(gnmi_pb2_grpc.gNMIServicer):
    def Capabilities(self, request, context):
        authorised(context)
        return gnmi_pb2.CapabilityResponse(
            supported_models=[gnmi_pb2.ModelData(name=n, organization=o, version=v) for n, o, v in MODELS],
            supported_encodings=[gnmi_pb2.JSON, gnmi_pb2.JSON_IETF],
            gNMI_version="0.8.0")

    def Get(self, request, context):
        authorised(context)
        tree = state_tree()
        ts = time.time_ns()
        notes = []
        for path in request.path:
            found = list(resolve(tree, elems(join(request.prefix, path))))
            if not found:
                context.abort(grpc.StatusCode.NOT_FOUND, "nothing at " + path_text(join(request.prefix, path)))
            n = gnmi_pb2.Notification(timestamp=ts)
            for es, v in found:
                n.update.add(path=to_path(es), val=typed(v, request.encoding))
            notes.append(n)
        return gnmi_pb2.GetResponse(notification=notes)

    def Set(self, request, context):
        authorised(context, write=True)
        results = []
        ops = [(gnmi_pb2.UpdateResult.DELETE, p, None) for p in request.delete] + \
              [(gnmi_pb2.UpdateResult.REPLACE, u.path, u.val) for u in request.replace] + \
              [(gnmi_pb2.UpdateResult.UPDATE, u.path, u.val) for u in request.update]
        lines = []
        for op, path, val in ops:
            es = elems(join(request.prefix, path))
            names = [n for n, _ in es]
            if names[:2] != ["interfaces", "interface"] or names[2:3] != ["config"] or len(es) != 4:
                context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                              "only /interfaces/interface[name=…]/config/{description,enabled} can be set")
            ifname, leaf = es[1][1].get("name"), names[3]
            if ifname not in state_tree()["interfaces"]["interface"]:
                context.abort(grpc.StatusCode.NOT_FOUND, f"no interface {ifname}")
            lines.append(f"interface {ifname}")
            if leaf == "description":
                if op == gnmi_pb2.UpdateResult.DELETE:
                    lines.append("no description")
                else:
                    v = scalar(val)
                    lines.append(f"description {v}")
            elif leaf == "enabled" and op != gnmi_pb2.UpdateResult.DELETE:
                v = scalar(val)
                if isinstance(v, str):
                    v = v.lower() == "true"
                lines.append("no shutdown" if v else "shutdown")
            else:
                context.abort(grpc.StatusCode.INVALID_ARGUMENT, f"{leaf} cannot be set here")
            lines.append("exit")
            results.append(gnmi_pb2.UpdateResult(path=path, op=op))
        try:
            configure(lines)
        except ValueError as e:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, str(e))
        return gnmi_pb2.SetResponse(prefix=request.prefix, response=results, timestamp=time.time_ns())

    def Subscribe(self, request_iterator, context):
        authorised(context)
        first = next(request_iterator)
        sl = first.subscribe
        prefix = sl.prefix
        subs = list(sl.subscription)

        def sample(paths):
            tree = state_tree()
            n = gnmi_pb2.Notification(timestamp=time.time_ns(), prefix=gnmi_pb2.Path(target=prefix.target))
            for p in paths:
                for es, v in resolve(tree, elems(join(prefix, p))):
                    for les, lv in leaves(es, v):
                        n.update.add(path=to_path(les), val=typed(lv, gnmi_pb2.JSON))
            return n

        def changes(paths, last):
            tree = state_tree()
            n = gnmi_pb2.Notification(timestamp=time.time_ns())
            for p in paths:
                for es, v in resolve(tree, elems(join(prefix, p))):
                    for les, lv in leaves(es, v):
                        key = path_text(to_path(les))
                        if last.get(key) != lv:
                            last[key] = lv
                            n.update.add(path=to_path(les), val=typed(lv, gnmi_pb2.JSON))
            return n

        all_paths = [s.path for s in subs]
        if sl.mode == gnmi_pb2.SubscriptionList.ONCE:
            yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
            yield gnmi_pb2.SubscribeResponse(sync_response=True)
            return
        if sl.mode == gnmi_pb2.SubscriptionList.POLL:
            yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
            yield gnmi_pb2.SubscribeResponse(sync_response=True)
            for req in request_iterator:
                if req.HasField("poll"):
                    yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
                    yield gnmi_pb2.SubscribeResponse(sync_response=True)
            return
        # STREAM: every subscription on its own clock
        last = {}
        timers = []
        for s in subs:
            if s.mode == gnmi_pb2.ON_CHANGE:
                timers.append(["change", s.path, 0.5, 0.0])
            else:
                iv = max((s.sample_interval or 10_000_000_000) / 1e9, 1.0)
                timers.append(["sample", s.path, iv, 0.0])
        n = changes([t[1] for t in timers if t[0] == "change"], last)
        s = sample([t[1] for t in timers if t[0] == "sample"])
        s.update.extend(n.update)
        yield gnmi_pb2.SubscribeResponse(update=s)
        yield gnmi_pb2.SubscribeResponse(sync_response=True)
        t0 = time.time()
        for t in timers:
            t[3] = t0 + t[2]
        while context.is_active():
            due = min(t[3] for t in timers)
            time.sleep(max(0.0, due - time.time()))
            for t in timers:
                if t[3] <= time.time():
                    t[3] += t[2]
                    n = sample([t[1]]) if t[0] == "sample" else changes([t[1]], last)
                    if n.update:
                        yield gnmi_pb2.SubscribeResponse(update=n)


def scalar(val):
    """The value of a TypedValue, whichever field the client chose to put it in."""
    raw = val.json_ietf_val or val.json_val
    if raw:
        try:
            return json.loads(raw)
        except ValueError:
            return raw.decode()
    return getattr(val, val.WhichOneof("value"))


def path_text(p):
    out = ""
    for e in p.elem:
        out += "/" + e.name + "".join(f"[{k}={v}]" for k, v in sorted(e.key.items()))
    return out or "/"


# ------------------------------------------------------------------------ main
def main():
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ctx.load_cert_chain(CONF["cert"], CONF["key"])
    httpd = ThreadingHTTPServer((CONF["address"], 443), Api)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    threading.Thread(target=watch_links, daemon=True).start()

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=16))
    gnmi_pb2_grpc.add_gNMIServicer_to_server(Gnmi(), server)
    creds = grpc.ssl_server_credentials([(open(CONF["key"], "rb").read(), open(CONF["cert"], "rb").read())])
    server.add_secure_port(f"{CONF['address']}:9339", creds)
    server.start()
    server.wait_for_termination()


if __name__ == "__main__":
    main()
DEVAPI
}

# ------------------------------------------------------- nc1: a model, managed
# nc1 has no forwarding plane at all. Its configuration is a document Clixon
# holds, checks against YANG (ietf-interfaces, ietf-ip and iana-if-type, the
# copies pyang ships) and serves over NETCONF on port 830 and RESTCONF on 443.
# Clixon is real and is the management plane of real products; the one piece
# written here is lab_restconf.so, which checks a RESTCONF password against
# /etc/clixon/users because Clixon leaves that to the product.
build_nc1() {
  local d=$LAB/nc1/etc/clixon v=$LAB/nc1/var/clixon m=$VENV/share/yang/modules
  mkdir -p "$d/yang" "$v" /usr/local/lib/lab/restconf
  write_lab_restconf > /usr/local/lib/lab/lab_restconf.c
  gcc -shared -fPIC -o /usr/local/lib/lab/restconf/lab_restconf.so /usr/local/lib/lab/lab_restconf.c -lclixon -lcrypto
  cp "$m/ietf/ietf-interfaces.yang" "$m/ietf/ietf-ip.yang" "$m/iana/iana-if-type.yang" "$d/yang/"
  cp "$LAB/ca/nc1.pem" "$LAB/ca/nc1.key" "$LAB/ca/ca.pem" "$d/"
  printf 'netops:%s\n' "$NETOPS_PASSWORD" > "$d/users"
  cat > "$d/nc1.xml" <<'C'
<clixon-config xmlns="http://clicon.org/config">
  <CLICON_CONFIGFILE>/etc/clixon/nc1.xml</CLICON_CONFIGFILE>
  <CLICON_FEATURE>ietf-netconf:startup</CLICON_FEATURE>
  <CLICON_FEATURE>ietf-netconf:candidate</CLICON_FEATURE>
  <CLICON_FEATURE>ietf-netconf:confirmed-commit</CLICON_FEATURE>
  <CLICON_FEATURE>ietf-netconf:validate</CLICON_FEATURE>
  <CLICON_FEATURE>ietf-netconf:xpath</CLICON_FEATURE>
  <CLICON_FEATURE>clixon-restconf:http-data</CLICON_FEATURE>
  <CLICON_YANG_DIR>/usr/local/share/clixon</CLICON_YANG_DIR>
  <CLICON_YANG_DIR>/etc/clixon/yang</CLICON_YANG_DIR>
  <CLICON_YANG_MAIN_DIR>/etc/clixon/yang</CLICON_YANG_MAIN_DIR>
  <CLICON_RESTCONF_DIR>/usr/local/lib/lab/restconf</CLICON_RESTCONF_DIR>
  <CLICON_RESTCONF_USER>root</CLICON_RESTCONF_USER>
  <CLICON_SOCK>/var/clixon/nc1.sock</CLICON_SOCK>
  <CLICON_SOCK_GROUP>netops</CLICON_SOCK_GROUP>
  <CLICON_BACKEND_PIDFILE>/var/clixon/nc1.pid</CLICON_BACKEND_PIDFILE>
  <CLICON_XMLDB_DIR>/var/clixon</CLICON_XMLDB_DIR>
  <CLICON_STARTUP_MODE>startup</CLICON_STARTUP_MODE>
  <CLICON_NACM_MODE>disabled</CLICON_NACM_MODE>
  <CLICON_YANG_LIBRARY>true</CLICON_YANG_LIBRARY>
  <restconf>
    <enable>true</enable>
    <auth-type>user</auth-type>
    <server-cert-path>/etc/clixon/nc1.pem</server-cert-path>
    <server-key-path>/etc/clixon/nc1.key</server-key-path>
    <server-ca-cert-path>/etc/clixon/ca.pem</server-ca-cert-path>
    <socket><namespace>default</namespace><address>192.0.2.21</address><port>443</port><ssl>true</ssl></socket>
  </restconf>
</clixon-config>
C
  cat > "$v/startup_db" <<'C'
<config>
  <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces">
    <interface>
      <name>eth0</name>
      <description>management</description>
      <type xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">ianaift:ethernetCsmacd</type>
      <enabled>true</enabled>
      <ipv4 xmlns="urn:ietf:params:xml:ns:yang:ietf-ip">
        <address><ip>192.0.2.21</ip><prefix-length>24</prefix-length></address>
      </ipv4>
    </interface>
    <interface>
      <name>eth1</name>
      <description>uplink to core1</description>
      <type xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">ianaift:ethernetCsmacd</type>
      <enabled>true</enabled>
    </interface>
    <interface>
      <name>eth2</name>
      <type xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">ianaift:ethernetCsmacd</type>
      <enabled>false</enabled>
    </interface>
  </interfaces>
</config>
C
  chgrp -R netops "$v"; chmod 770 "$v"
  exec_on nc1 root 'clixon_backend -f /etc/clixon/nc1.xml -s startup -l f/var/clixon/backend.log'
  sleep 1
  exec_on nc1 root 'setsid clixon_restconf -f /etc/clixon/nc1.xml -l f/var/clixon/restconf.log </dev/null >/dev/null 2>&1 &'
  exec_on nc1 root '/usr/sbin/sshd -f /etc/ssh/sshd_config'
}

write_lab_restconf() {
cat <<'LABRESTCONF'
/* lab_restconf: HTTP basic authentication for nc1's RESTCONF, written for the lab.
 *
 * Clixon leaves "who is this" to a plugin, because a product decides it against
 * its own user database. This one reads user:password lines from
 * /etc/clixon/users and nothing else. The shape follows Clixon's own
 * example/main/example_restconf.c.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <cligen/cligen.h>
#include <clixon/clixon.h>
#include <clixon/clixon_restconf.h>

static int
lab_auth(clixon_handle h, void *req, clixon_auth_type_t auth_type, char **authp)
{
    char *auth, *colon, line[256];
    unsigned char dec[256];
    int n;
    FILE *f;

    if (auth_type != CLIXON_AUTH_USER)
        return 0;
    *authp = NULL;
    if ((auth = restconf_param_get(h, "HTTP_AUTHORIZATION")) == NULL ||
        strncmp(auth, "Basic ", 6) != 0 || strlen(auth + 6) > 160)
        return 1;
    if ((n = EVP_DecodeBlock(dec, (unsigned char *)auth + 6, strlen(auth + 6))) < 0)
        return 1;
    dec[n] = '\0';
    if ((colon = strchr((char *)dec, ':')) == NULL)
        return 1;
    if ((f = fopen("/etc/clixon/users", "r")) == NULL)
        return 1;
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = '\0';
        if (strcmp(line, (char *)dec) == 0) {
            *colon = '\0';
            *authp = strdup((char *)dec);
            break;
        }
    }
    fclose(f);
    return 1;
}

clixon_plugin_api *clixon_plugin_init(clixon_handle h);

static clixon_plugin_api api = {
    "lab",
    clixon_plugin_init,
    NULL,
    NULL,
    .ca_auth = lab_auth,
};

clixon_plugin_api *
clixon_plugin_init(clixon_handle h)
{
    return &api;
}
LABRESTCONF
}

# ------------------------------------------------------------------ NetBox
# NetBox v4.6.10 (commit 560da79e), cloned into /opt/netbox with its own venv
# from its requirements.txt. PostgreSQL 16 and Redis run inside the netbox
# machine. Migrating an empty database takes minutes, so the first build keeps
# a copy of the migrated and seeded database in /var/cache/lab and later builds
# unpack it: the objects, their ids and their creation times are the same on
# every build after the first.
NETBOX_ADMIN_PASSWORD='lab-netbox-26'
NETBOX_TOKEN_KEY='labanatoken0'
NETBOX_TOKEN='4f1c2e8b9a7d6c5e3b2a1f0e9d8c7b6a5f4e3d2c'
build_netbox() {
  local d=$LAB/netbox cache=/var/cache/lab/netbox-pg.tar
  mkdir -p "$d/pg" "$d/run" "$d/redis" /var/cache/lab
  chown -R postgres:postgres "$d/pg" "$d/run"
  cp "$LAB/ca/netbox.pem" "$LAB/ca/netbox.key" "$d/"
  chmod 644 "$d/netbox.key"
  cat > "$NETBOX/netbox/netbox/configuration.py" <<C
ALLOWED_HOSTS = ['netbox.example.net', 'netbox', '192.0.2.30']
DATABASES = {'default': {'ENGINE': 'django.db.backends.postgresql', 'NAME': 'netbox',
             'USER': 'netbox', 'PASSWORD': 'netbox', 'HOST': '$d/run', 'PORT': ''}}
REDIS = {'tasks': {'HOST': '127.0.0.1', 'PORT': 6379, 'DATABASE': 0, 'SSL': False},
         'caching': {'HOST': '127.0.0.1', 'PORT': 6379, 'DATABASE': 1, 'SSL': False}}
SECRET_KEY = 'lab-only-3f9a7c1e5b2d8f4a6c0e9b7d5f3a1c8e6b4d2f0a9c7e5b3d1f8a6c4e2b0d9f7'
API_TOKEN_PEPPERS = {1: 'lab-only-pepper-7c1e5b2d8f4a6c0e9b7d5f3a1c8e6b4d2f0'}
TIME_ZONE = 'America/Sao_Paulo'
LOGIN_REQUIRED = True
C
  local nb="$NETBOX/venv/bin/python $NETBOX/netbox/manage.py"
  local pg=/usr/lib/postgresql/16/bin
  if [ -f "$cache" ]; then
    tar -C "$d" -xf "$cache"
  else
    exec_on netbox root "runuser -u postgres -- $pg/initdb -A trust -D $d/pg --locale=C.UTF-8 >/dev/null"
  fi
  exec_on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg -l $d/run/pg.log -o '-k $d/run -c listen_addresses=' start"
  exec_on netbox root "redis-server --bind 127.0.0.1 --port 6379 --dir $d/redis --daemonize yes --logfile $d/redis.log"
  if [ ! -f "$cache" ]; then
    exec_on netbox root "runuser -u postgres -- psql -q -h $d/run -c \"CREATE USER netbox PASSWORD 'netbox'\" -c 'CREATE DATABASE netbox OWNER netbox'"
    exec_on netbox root "$nb migrate --no-input >/dev/null && $nb collectstatic --no-input >/dev/null"
    write_netbox_seed > "$d/seed.py"
    exec_on netbox root "ADMIN_PASSWORD='$NETBOX_ADMIN_PASSWORD' TOKEN_KEY='$NETBOX_TOKEN_KEY' TOKEN='$NETBOX_TOKEN' $nb shell < $d/seed.py"
    exec_on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg stop"
    tar -C "$d" -cf "$cache" pg
    exec_on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg -l $d/run/pg.log -o '-k $d/run -c listen_addresses=' start"
  fi
  exec_on netbox root "cd $NETBOX/netbox; setsid $NETBOX/venv/bin/gunicorn --bind 192.0.2.30:443 --workers 3 --certfile $d/netbox.pem --keyfile $d/netbox.key --access-logfile $d/access.log --error-logfile $d/gunicorn.log netbox.wsgi </dev/null >/dev/null 2>&1 &"
  exec_on netbox root "setsid $nb rqworker high default low </dev/null >>$d/rqworker.log 2>&1 &"
  printf 'nbt_%s.%s\n' "$NETBOX_TOKEN_KEY" "$NETBOX_TOKEN" > "$LAB/ctl/home/ana/.netbox-token"
  chown ana:ana "$LAB/ctl/home/ana/.netbox-token"; chmod 600 "$LAB/ctl/home/ana/.netbox-token"
}

write_netbox_seed() {
cat <<'NETBOXSEED'
# What NetBox holds when the lab is built: the three routers and nc1, where
# they are, their interfaces and addresses, and how they are cabled. Run once,
# through `manage.py shell`, on the first build.
import os
from dcim.models import (Cable, Device, DeviceRole, DeviceType, Interface,
                         InterfaceTemplate, Manufacturer, Platform, Site)
from ipam.models import IPAddress, Prefix
from users.models import Token, User

admin = User.objects.create_superuser("admin", "admin@example.net", os.environ["ADMIN_PASSWORD"])
ana = User.objects.create_user("ana", "ana@example.net", os.environ["ADMIN_PASSWORD"])
ana.is_superuser = True
ana.save()
Token.objects.create(user=ana, version=2, pepper_id=1, key=os.environ["TOKEN_KEY"],
                     token=os.environ["TOKEN"], write_enabled=True,
                     description="ana's automation on ctl")

sites = {}
for name, slug in (("Core", "core"), ("Branch 1", "branch-1"), ("Branch 2", "branch-2")):
    sites[slug] = Site.objects.create(name=name, slug=slug, status="active",
                                      time_zone="America/Sao_Paulo")

lab = Manufacturer.objects.create(name="Lab", slug="lab")
router_t = DeviceType.objects.create(manufacturer=lab, model="FRR router", slug="frr-router")
switch_t = DeviceType.objects.create(manufacturer=lab, model="Clixon switch", slug="clixon-switch")
for t in (router_t, switch_t):
    InterfaceTemplate.objects.create(device_type=t, name="eth0", type="1000base-t", mgmt_only=True)
    InterfaceTemplate.objects.create(device_type=t, name="eth1", type="1000base-t")
    InterfaceTemplate.objects.create(device_type=t, name="eth2", type="1000base-t")
InterfaceTemplate.objects.create(device_type=router_t, name="lo", type="virtual")

router = DeviceRole.objects.create(name="Router", slug="router", color="2f6f4e")
switch = DeviceRole.objects.create(name="Switch", slug="switch", color="3f51b5")
frr = Platform.objects.create(name="FRR", slug="frr")
clixon = Platform.objects.create(name="Clixon", slug="clixon")

devices = {}
for name, site, dtype, role, platform in (
        ("core1", "core", router_t, router, frr),
        ("edge1", "branch-1", router_t, router, frr),
        ("edge2", "branch-2", router_t, router, frr),
        ("nc1", "core", switch_t, switch, clixon)):
    devices[name] = Device.objects.create(name=name, site=sites[site], device_type=dtype,
                                          role=role, platform=platform, status="active")


def iface(dev, name):
    return Interface.objects.get(device=devices[dev], name=name)


ADDRESSES = [
    ("core1", "eth0", "192.0.2.11/24", ""), ("edge1", "eth0", "192.0.2.12/24", ""),
    ("edge2", "eth0", "192.0.2.13/24", ""), ("nc1", "eth0", "192.0.2.21/24", ""),
    ("core1", "eth1", "198.51.100.1/30", "link to edge1"),
    ("core1", "eth2", "198.51.100.5/30", "link to edge2"),
    ("edge1", "eth1", "198.51.100.2/30", "uplink to core1"),
    ("edge2", "eth1", "198.51.100.6/30", "uplink to core1"),
    ("edge1", "eth2", "203.0.113.1/26", "branch LAN"),
    ("edge2", "eth2", "203.0.113.65/26", "branch LAN"),
    ("core1", "lo", "203.0.113.251/32", ""), ("edge1", "lo", "203.0.113.252/32", ""),
    ("edge2", "lo", "203.0.113.253/32", ""),
]
for dev, name, address, description in ADDRESSES:
    i = iface(dev, name)
    if description:
        i.description = description
        i.save()
    ip = IPAddress.objects.create(address=address, status="active", assigned_object=i,
                                  dns_name=f"{dev}.example.net" if name == "eth0" else "")
    if name == "eth0":
        devices[dev].primary_ip4 = ip
        devices[dev].save()

for prefix, description in (("192.0.2.0/24", "management"), ("198.51.100.0/30", "core1-edge1"),
                            ("198.51.100.4/30", "core1-edge2"), ("203.0.113.0/26", "branch 1 LAN"),
                            ("203.0.113.64/26", "branch 2 LAN")):
    Prefix.objects.create(prefix=prefix, status="active", description=description)

for a, b in ((("core1", "eth1"), ("edge1", "eth1")), (("core1", "eth2"), ("edge2", "eth1"))):
    Cable.objects.create(a_terminations=[iface(*a)], b_terminations=[iface(*b)], status="connected")

print("seeded", Device.objects.count(), "devices,", Interface.objects.count(), "interfaces,",
      IPAddress.objects.count(), "addresses")
NETBOXSEED
}

# ---------------------------------------------------------- the service desk
DESK_TOKEN='9d2f6b1c8e4a7f3d5b0c2e6a9f1d4b8c'
build_desk() {
  local d=$LAB/tickets
  mkdir -p "$d/etc/deskd" "$d/var/lib/deskd" /opt/lab
  write_deskd > /opt/lab/deskd.py
  cp "$LAB/ca/tickets.pem" "$LAB/ca/tickets.key" "$d/etc/deskd/"
  cat > "$d/etc/deskd/deskd.json" <<C
{"address": "192.0.2.40", "token": "$DESK_TOKEN",
 "cert": "/etc/deskd/tickets.pem", "key": "/etc/deskd/tickets.key"}
C
  exec_on tickets root "setsid $VENV/bin/python /opt/lab/deskd.py </dev/null >>/var/lib/deskd/deskd.err 2>&1 &"
  printf '%s\n' "$DESK_TOKEN" > "$LAB/ctl/home/ana/.desk-token"
  chown ana:ana "$LAB/ctl/home/ana/.desk-token"; chmod 600 "$LAB/ctl/home/ana/.desk-token"
}

write_deskd() {
cat <<'DESKD'
#!/opt/netauto/bin/python
"""deskd: the lab's service desk, written for this course.

Lesson 7 opens tickets from network events, and the ticketing systems people
use at work (ServiceNow, Jira Service Management, Zammad, GLPI) are either
licensed or a small data centre to install. What they have in common is small,
and this is that part: tickets with a number, a status and comments, behind a
JSON API that takes a token in the Authorization header.

  POST   /api/tickets                 {"title", "body", "priority", "requester"}
  GET    /api/tickets?status=open&q=  search (q matches the title)
  GET    /api/tickets/<number>
  PATCH  /api/tickets/<number>        {"status": "open" | "resolved"}
  POST   /api/tickets/<number>/comments {"body"}

Tickets are kept in /var/lib/deskd/tickets.json and numbered from INC-1001.
"""
import json
import ssl
import sys
import threading
import urllib.parse
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONF = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "/etc/deskd/deskd.json"))
STORE = "/var/lib/deskd/tickets.json"
LOCK = threading.Lock()


def load():
    try:
        return json.load(open(STORE))
    except FileNotFoundError:
        return []


def save(tickets):
    with open(STORE, "w") as f:
        json.dump(tickets, f, indent=1)


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


class Desk(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def version_string(self):
        return "deskd/1.0"

    def log_message(self, fmt, *args):
        with open("/var/lib/deskd/access.log", "a") as f:
            f.write("%s %s %s\n" % (now(), self.address_string(), fmt % args))

    def send(self, status, body):
        data = (json.dumps(body, indent=2) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            return None
        return data if isinstance(data, dict) else None

    def route(self, verb):
        if self.headers.get("Authorization") != "Token " + CONF["token"]:
            return self.send(401, {"error": "send Authorization: Token <your token>"})
        url = urllib.parse.urlsplit(self.path)
        parts = [p for p in url.path.split("/") if p]
        q = urllib.parse.parse_qs(url.query)
        with LOCK:
            tickets = load()
            if parts == ["api", "tickets"] and verb == "GET":
                found = [t for t in tickets
                         if ("status" not in q or t["status"] == q["status"][0])
                         and ("q" not in q or q["q"][0].lower() in t["title"].lower())]
                return self.send(200, {"count": len(found), "results": found})
            if parts == ["api", "tickets"] and verb == "POST":
                b = self.body()
                if not b or not b.get("title"):
                    return self.send(400, {"error": "a ticket needs at least a title"})
                if b.get("priority", "normal") not in ("low", "normal", "high"):
                    return self.send(400, {"error": "priority is low, normal or high"})
                t = {"number": f"INC-{1001 + len(tickets)}", "title": b["title"],
                     "body": b.get("body", ""), "priority": b.get("priority", "normal"),
                     "requester": b.get("requester", ""), "status": "open",
                     "opened": now(), "comments": []}
                tickets.append(t)
                save(tickets)
                return self.send(201, t)
            if len(parts) >= 3 and parts[:2] == ["api", "tickets"]:
                t = next((t for t in tickets if t["number"] == parts[2]), None)
                if not t:
                    return self.send(404, {"error": f"no ticket {parts[2]}"})
                if len(parts) == 3 and verb == "GET":
                    return self.send(200, t)
                if len(parts) == 3 and verb == "PATCH":
                    b = self.body()
                    if not b or b.get("status") not in ("open", "resolved"):
                        return self.send(400, {"error": "status is open or resolved"})
                    t["status"] = b["status"]
                    save(tickets)
                    return self.send(200, t)
                if parts[3:] == ["comments"] and verb == "POST":
                    b = self.body()
                    if not b or not b.get("body"):
                        return self.send(400, {"error": "a comment needs a body"})
                    t["comments"].append({"time": now(), "body": b["body"]})
                    save(tickets)
                    return self.send(201, t)
            return self.send(404, {"error": f"nothing for {verb} {url.path}"})

    def do_GET(self): self.route("GET")
    def do_POST(self): self.route("POST")
    def do_PATCH(self): self.route("PATCH")


def main():
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ctx.load_cert_chain(CONF["cert"], CONF["key"])
    httpd = ThreadingHTTPServer((CONF["address"], 443), Desk)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
DESKD
}

write_napalm_frr() {
cat <<'NAPALMFRR'
"""napalm_frr: a NAPALM driver for FRR, written for the lab.

NAPALM ships drivers for EOS, IOS, IOS-XR, Junos and NX-OS, and none for FRR.
NAPALM finds a driver it does not ship by importing a package called
napalm_<name>, which is how community drivers work, so this is one:
get_network_driver("frr") imports it.

How it does what it does, so nothing about it is magic:
  - it logs in with Netmiko, as the cisco_ios device type (FRR's CLI is
    modelled on Cisco's, and that driver's prompts and paging match it);
  - the getters read FRR's own JSON (`show interface json`, `show version`);
  - a replace is worked out by FRR's frr-reload.py, the tool FRR ships for
    exactly that: it compares two configurations context by context and says
    which lines to remove and which to add. This driver sends those lines.
  - a commit saves the configuration it replaced, which is what rollback()
    puts back.
"""
import importlib.util
import os
import tempfile
import warnings

from napalm.base import NetworkDriver
from napalm.base.exceptions import (ConnectionClosedException, MergeConfigException,
                                    ReplaceConfigException)
from netmiko import ConnectHandler

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    _spec = importlib.util.spec_from_file_location("frr_reload", "/usr/lib/frr/frr-reload.py")
    frr_reload = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(frr_reload)


def _clean(text):
    """Drop the lines vtysh prints around a configuration that are not configuration."""
    skip = ("Building configuration", "Current configuration")
    return "\n".join(l for l in text.splitlines() if not l.startswith(skip)) + "\n"


class FRRDriver(NetworkDriver):
    def __init__(self, hostname, username, password, timeout=60, optional_args=None):
        self.hostname, self.username, self.password, self.timeout = hostname, username, password, timeout
        self.optional_args = optional_args or {}
        self.device = None
        self.candidate = None     # the text loaded, or None
        self.merge = None
        self.rollback_config = None

    # ------------------------------------------------------------- the session
    def open(self):
        args = {"device_type": "cisco_ios", "host": self.hostname, "username": self.username,
                "timeout": self.timeout}
        if self.password:
            args["password"] = self.password
        else:
            args.update(use_keys=True, key_file=self.optional_args.get("key_file"))
        self.device = ConnectHandler(**args)

    def close(self):
        if self.device:
            self.device.disconnect()
            self.device = None

    def is_alive(self):
        return {"is_alive": bool(self.device and self.device.is_alive())}

    def _show(self, command):
        if not self.device:
            raise ConnectionClosedException("open() first")
        return self.device.send_command(command)

    # ---------------------------------------------------------------- getters
    def get_facts(self):
        import json
        first = self._show("show version").splitlines()[0]          # FRRouting 8.4.4 (edge1) on Linux(...)
        name = first.split("(")[1].split(")")[0]
        interfaces = json.loads(self._show("show interface json"))
        return {"hostname": name, "fqdn": f"{name}.example.net", "vendor": "FRRouting",
                "model": "FRR", "os_version": first.split(" (")[0].split()[-1],
                "serial_number": "", "uptime": -1.0,   # FRR does not report the router's uptime
                "interface_list": sorted(interfaces)}

    def get_interfaces(self):
        import json
        out = {}
        for name, i in json.loads(self._show("show interface json")).items():
            out[name] = {"is_up": i.get("operationalStatus") == "up",
                         "is_enabled": i.get("administrativeStatus") == "up",
                         "description": i.get("description", ""),
                         "last_flapped": -1.0, "speed": float(i.get("speed", 0)),
                         "mtu": i.get("mtu", 0), "mac_address": i.get("hardwareAddress", "")}
        return out

    def get_interfaces_ip(self):
        import json
        out = {}
        for name, i in json.loads(self._show("show interface json")).items():
            for a in i.get("ipAddresses", []):
                ip, plen = a["address"].split("/")
                out.setdefault(name, {"ipv4": {}})["ipv4"][ip] = {"prefix_length": int(plen)}
        return out

    def get_config(self, retrieve="all", full=False, sanitized=False, format="text"):
        running = _clean(self._show("show running-config")) if retrieve in ("all", "running") else ""
        return {"running": running, "startup": "", "candidate": self.candidate or ""}

    # ----------------------------------------------------------- configuration
    def _load(self, filename, config, merge):
        if filename:
            with open(filename) as f:
                config = f.read()
        self.candidate, self.merge = config, merge

    def load_merge_candidate(self, filename=None, config=None):
        self._load(filename, config, True)

    def load_replace_candidate(self, filename=None, config=None):
        self._load(filename, config, False)

    def discard_config(self):
        self.candidate = self.merge = None

    def _changes(self):
        """(lines to delete, lines to add), each a list of commands with their context."""
        if self.candidate is None:
            return [], []
        if self.merge:
            lines = [l for l in self.candidate.splitlines() if l.strip() and l.strip() != "!"]
            return [], [lines]
        vtysh = frr_reload.Vtysh(bindir="/usr/bin")
        with tempfile.TemporaryDirectory() as d:
            files = {}
            for kind, text in (("running", self.get_config("running")["running"]), ("new", self.candidate)):
                files[kind] = os.path.join(d, kind + ".conf")
                with open(files[kind], "w") as f:
                    f.write(_clean(text))
            configs = {}
            for kind, path in files.items():
                c = frr_reload.Config(vtysh)
                c.load_from_file(path)
                configs[kind] = c
        add, delete = frr_reload.compare_context_objects(configs["new"], configs["running"])
        todel = [frr_reload.lines_to_config(k, l, True) for k, l in delete if l != "!"]
        toadd = [frr_reload.lines_to_config(k, l, False) for k, l in add if l != "!"]
        return todel, toadd

    def compare_config(self):
        """The change as a diff: context lines as they are, then - or + and the line."""
        out = []
        for sign, groups in zip("-+", self._changes()):
            for cmd in groups:
                last = cmd[-1]
                if sign == "-":   # show the line that goes, not the command that removes it
                    indent = last[:len(last) - len(last.lstrip())]
                    last = indent + last.lstrip()[3:]
                out += cmd[:-1] + [sign + last]
        return "\n".join(out)

    def _send(self, commands):
        """Send configuration commands; return the lines the router answered with %."""
        output = self.device.send_config_set(commands)
        return [l.strip() for l in output.splitlines() if l.lstrip().startswith("%")]

    def commit_config(self, message="", revert_in=None):
        if self.candidate is None:
            return
        todel, toadd = self._changes()
        before = self.get_config("running")["running"]
        errors = []
        if self.merge:
            errors += self._send(toadd[0])
        else:
            # A "no" form FRR refuses is retried shorter, a word at a time, as
            # frr-reload.py does: `no description branch LAN` is `no description`.
            for cmd in todel:
                while self._send(cmd + ["exit"] * (len(cmd) - 1)):
                    words = cmd[-1].split()
                    if len(words) <= 2:
                        errors.append("could not remove: " + " / ".join(c.strip() for c in cmd))
                        break
                    indent = cmd[-1][:len(cmd[-1]) - len(cmd[-1].lstrip())]
                    cmd = cmd[:-1] + [indent + " ".join(words[:-1])]
            for cmd in toadd:
                errors += self._send(cmd + ["exit"] * (len(cmd) - 1))
        if errors:
            exc = MergeConfigException if self.merge else ReplaceConfigException
            raise exc("the router refused: " + "; ".join(errors))
        self.device.save_config()
        self.rollback_config = before
        self.discard_config()

    def rollback(self):
        if self.rollback_config is None:
            return
        self.load_replace_candidate(config=self.rollback_config)
        self.commit_config()
NAPALMFRR
}

# The lab is up when everything a lesson talks to answers: both OSPF
# adjacencies on core1 are Full, and every API accepts a connection.
wait_ready() {
  local i
  for i in $(seq 120); do
    [ "$(exec_on core1 root 'vtysh -c "show ip ospf neighbor"' | grep -c Full)" = 2 ] && break
    sleep 1
  done
  # and each branch has learnt the other one's LAN, which is what routing is for
  for i in $(seq 120); do
    exec_on edge1 root 'ip route show 203.0.113.64/26' | grep -q via &&
      exec_on edge2 root 'ip route show 203.0.113.0/26' | grep -q via && break
    sleep 1
  done
  for a in 192.0.2.11:443 192.0.2.12:443 192.0.2.13:443 192.0.2.11:9339 192.0.2.12:9339 \
           192.0.2.13:9339 192.0.2.21:443 192.0.2.21:830 192.0.2.30:443 192.0.2.40:443; do
    for i in $(seq 120); do
      exec_on ctl root "timeout 1 bash -c '</dev/tcp/${a%:*}/${a#*:}'" 2>/dev/null && break
      sleep 1
    done
  done
}

# ------------------------------------------------------------- the SDN corner
# Lesson 15's switch. Open vSwitch runs inside sw1 with the userspace datapath
# (datapath_type=netdev), because the kernel module is not something a lab
# should load into somebody's machine; it forwards the same OpenFlow, slower.
# br0 starts with fail_mode=secure and no controller, so it forwards nothing
# until the lesson gives it flows: that empty table is the first thing shown.
build_sdn() {
  local i d=$LAB/sw1
  for i in 1 2 3; do
    ip link add "p$i" type veth peer name "lab-sdn$i"
    ip link set "p$i" netns sw1
    ip link set "lab-sdn$i" netns "h$i"
    ip -n "h$i" link set "lab-sdn$i" name eth0
    ip -n "h$i" link set eth0 address "$(mac "203.0.113.$((128 + i))")"
    ip -n "h$i" addr add "203.0.113.$((128 + i))/27" dev eth0
    ip -n "h$i" link set eth0 up
    ip -n sw1 link set "p$i" up
  done
  mkdir -p "$d/etc/openvswitch" "$d/run/openvswitch" "$d/var/log/openvswitch"
  ovsdb-tool create "$d/etc/openvswitch/conf.db" /usr/share/openvswitch/vswitch.ovsschema
  exec_on sw1 root 'ovsdb-server /etc/openvswitch/conf.db --remote=punix:/run/openvswitch/db.sock -vconsole:off \
      --pidfile --detach --log-file=/var/log/openvswitch/ovsdb-server.log
    ovs-vsctl --no-wait init
    ovs-vswitchd --pidfile --detach -vconsole:off --log-file=/var/log/openvswitch/ovs-vswitchd.log
    ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev fail_mode=secure \
      protocols=OpenFlow13 other-config:datapath-id=0000000000000001
    for i in 1 2 3; do ovs-vsctl add-port br0 p$i -- set interface p$i ofport_request=$i; done'
  # ana works the switch as an operator would, without root: the sockets are
  # her group's. A real switch would give her a role; this is the lab's.
  exec_on sw1 root 'chgrp -R ana /run/openvswitch && chmod -R g+rwX /run/openvswitch'
}

# ------------------------------------------------------------------- the verbs
down() {
  for h in $HOSTS; do
    ip netns pids "$h" 2>/dev/null | xargs -r kill 2>/dev/null || true
  done
  sleep 1
  for h in $HOSTS wire; do
    ip netns pids "$h" 2>/dev/null | xargs -r kill -9 2>/dev/null || true
    ip netns del "$h" 2>/dev/null || true
  done
  rm -rf "$LAB" /etc/netns/*
}

up() {
  need
  ip netns list | grep -qw ctl && return 0
  build_net
  hostfiles
  build_ca
  build_frr
  build_ssh
  build_devapi
  build_nc1
  build_netbox
  build_desk
  build_sdn
  wait_ready
}

case ${1:-} in
  tools) tools ;;
  up)    up ;;
  down)  down ;;
  reset) down; up ;;
  exec)  exec_on "$2" "$3" "$4" ;;
  *) sed -n '2,50p' "$0"; exit 2 ;;
esac
