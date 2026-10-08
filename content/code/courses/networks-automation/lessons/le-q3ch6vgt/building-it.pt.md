---
title: Construindo a rede
version: 1
---

O laboratório é um script, o `netlab.sh`, e ele está impresso aqui inteiro. Você não precisa
entendê-lo antes de usar: a aula 1 é sobre por que a automação existe, e este script é o oposto do
que o curso ensina, um programa longo em shell que constrói uma rede específica à mão. Leia agora
se quiser ver como nove máquinas cabem num computador, ou depois, quando uma aula disser "o
laboratório faz isto" e você quiser conferir.

Crie um diretório para ele na sua home, na máquina virtual:

```sh
mkdir -p ~/netlab
```

Depois salve o script como `~/netlab/netlab.sh`:

```bash
#!/usr/bin/env bash
# netlab.sh: the network this course runs on, built inside one Ubuntu 24.04 machine.
#
# Each machine below is a network namespace with its own interfaces, routes and
# hostname, and its own copy of the directories a machine is told apart by. The
# cables are virtual Ethernet pairs plugged into bridges.
#
#   ctl       the automation host: ana's Python, Ansible and Git live here
#   core1     a router: FRR, SSH to its CLI, a REST API and a gNMI port
#   edge1     the same, at the edge of branch 1
#   edge2     the same, at the edge of branch 2
#   nc1       a device managed only through its model: NETCONF and RESTCONF
#   netbox    NetBox, the source of truth of lesson 12
#   tickets   the service desk the webhooks of lesson 7 open tickets in
#   pc1, pc2  one computer on each branch's LAN, to test the network from
#   sw1       an OpenFlow switch, Open vSwitch, for lesson 15
#   h1-h3     three computers plugged into sw1
#
# The services start once the lesson that introduces them has given you their
# program, saved beside this script: devapid.py (lesson 2), lab_restconf.c
# (lesson 3), deskd.py (lesson 7), napalm_frr.py (lesson 8), netbox_seed.py
# (lesson 12). `up` says which it started and which it skipped.
#
#   sudo ./netlab.sh up                  build it
#   sudo ./netlab.sh reset               tear it down and build it again
#   sudo ./netlab.sh down
#   sudo ./netlab.sh enter HOST [USER]   a shell on HOST, as ana unless told
#   sudo ./netlab.sh enter HOST USER 'command'
#
# Nothing here reaches the internet: the addresses are the ranges reserved for
# documentation (RFC 5737) and the names end in example.net (RFC 2606).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=/var/lib/netlab
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
SDN_HOSTS="h1 h2 h3"     # cabled straight to sw1's ports, in build_sdn
HOSTS=$( (echo "$LINKS" | awk 'NF{print $2}'; printf '%s\n' $SDN_HOSTS) | sort -u)
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
addr_of() { awk -v h="$1" '$2==h{print $1}' <<< "$NAMES"; }

# The lab's passwords and tokens. They open nothing outside this machine.
NETOPS_PASSWORD='lab-netops-26'
AUDIT_PASSWORD='lab-audit-26'
DESK_TOKEN='9d2f6b1c8e4a7f3d5b0c2e6a9f1d4b8c'
NETBOX_ADMIN_PASSWORD='lab-netbox-26'
NETBOX_TOKEN_KEY='labanatoken0'
NETBOX_TOKEN='4f1c2e8b9a7d6c5e3b2a1f0e9d8c7b6a5f4e3d2c'

say() { printf 'netlab: %s\n' "$*"; }

need() {
  [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
  local missing=() p
  for p in iproute2 frr frr-pythontools openssh-server openssl python3-venv openvswitch-switch; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  [ -x "$VENV/bin/python" ] || { echo "missing $VENV: make the virtual environment first" >&2; exit 1; }
}

# ---------------------------------------------------------------- ana, on ctl
# ana is the engineer whose sessions the lessons show. She has an account on
# this machine, and her home directory is the real /home/ana, so what you write
# there survives a reset.
operator() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  getent group frrvty >/dev/null && usermod -aG frrvty ana   # frr-reload.py reads vtysh.conf
  install -d -o ana -g ana -m 700 /home/ana/.ssh
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
# tells one machine from another lives under /var/lib/netlab/HOST and is mounted
# over the real path when something runs "on" that host.
OVERLAY="home etc/frr run/frr var/log/frr etc/ssh etc/devapi etc/clixon var/clixon etc/deskd var/lib/deskd
         etc/openvswitch run/openvswitch var/log/openvswitch"
overlay() {
  local h=$1 p
  for p in $OVERLAY; do
    [ -e "$LAB/$h/$p" ] && { [ -e "/$p" ] || mkdir -p "/$p"; } && mount --bind "$LAB/$h/$p" "/$p"
  done
  return 0
}

# on HOST USER COMMAND: run COMMAND on HOST, as USER; with no COMMAND, a shell.
on() {
  local h=$1 u=$2 c=${3:-}
  ip netns exec "$h" unshare --uts bash -c '
    '"$(declare -f overlay)"'; LAB='"$LAB"'; OVERLAY="'"$OVERLAY"'"
    hostname "$1"; overlay "$1"
    P=/opt/netauto/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin
    E="PATH=$P TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=${COLUMNS:-100}"
    if [ "$2" = root ]; then H=/root; else H=/home/$2; fi
    run() { if [ "$1" = root ]; then env -i HOME=/root USER=root LOGNAME=root $E "${@:2}"
            else runuser -u "$1" -- env -i HOME="$H" USER="$1" LOGNAME="$1" $E "${@:2}"; fi; }
    if [ -n "$3" ]; then run "$2" bash -c "cd; $3"; else cd "$H"; run "$2" bash -i; fi
    ' _ "$h" "$u" "$c"
}

hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h"
    {
      printf '127.0.0.1 localhost\n'
      grep -qw "$h" <<< "$NAMES" || printf '127.0.1.1 %s\n' "$h"
      echo "$NAMES" | awk 'NF{printf "%s %s.example.net %s\n", $1, $2, $2}'
    } > "/etc/netns/$h/hosts"
    : > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    # every machine but ctl gets a home of its own; ctl's is the real one
    if [ "$h" != ctl ]; then
      mkdir -p "$LAB/$h/home/ana"
      cp -a /etc/skel/. "$LAB/$h/home/ana/"
      chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
    fi
  done
}

# ------------------------------------------------------------------ the routers
# Three routers joined by two point-to-point links, OSPF between them, and a
# branch LAN behind each edge. Their management port, eth0, is addressed above;
# everything else comes from frr.conf.
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
    on "$r" root '/usr/lib/frr/frrinit.sh start' >/dev/null
  done
}

# ---------------------------------------------------------------- SSH to them
# netops is the account automation logs in with. Its shell is vtysh, so an SSH
# session lands in the router's CLI and not in Linux, as it would on a router.
build_ssh() {
  id netops >/dev/null 2>&1 || useradd -M -d /home/netops -s /usr/bin/vtysh -G frrvty netops
  echo "netops:$NETOPS_PASSWORD" | chpasswd
  grep -qx /usr/bin/vtysh /etc/shells || echo /usr/bin/vtysh >> /etc/shells
  mkdir -p /run/sshd
  # ana's key, made once on ctl and trusted by every router
  local k=/home/ana/.ssh
  [ -f "$k/id_ed25519" ] || runuser -u ana -- ssh-keygen -q -t ed25519 -N '' -C ana@ctl -f "$k/id_ed25519"
  : > "$k/known_hosts"
  for h in $ROUTERS nc1; do
    local s="$LAB/$h/etc/ssh" a; a=$(addr_of "$h")
    mkdir -p "$s" "$LAB/$h/home/netops/.ssh"
    ssh-keygen -q -t ed25519 -N '' -C "root@$h" -f "$s/ssh_host_ed25519_key"
    ssh-keygen -q -t rsa -b 3072 -N '' -C "root@$h" -f "$s/ssh_host_rsa_key"
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
    # nc1's sshd starts with Clixon, in build_nc1, because its NETCONF
    # subsystem needs Clixon's files to be there when sshd starts.
    [ "$h" = nc1 ] || on "$h" root '/usr/sbin/sshd -f /etc/ssh/sshd_config'
  done
  chown ana:ana "$k/known_hosts"
  # The passwords ana's programs read, one file each, readable by her alone:
  # a secret in a file with mode 0600 is the lab's stand-in for a vault.
  secret .netops-password "$NETOPS_PASSWORD"
  secret .audit-password "$AUDIT_PASSWORD"
  # and a .netrc for nc1, whose RESTCONF takes HTTP Basic: curl -n reads it, and
  # so does requests. Only nc1: requests lets a .netrc entry replace the Bearer
  # token a session sends, so an entry for a router would break lesson 2.
  secret .netrc "machine nc1.example.net login netops password $NETOPS_PASSWORD"
}

secret() {  # secret FILE TEXT: a file in ana's home that only she can read
  printf '%s\n' "$2" > "/home/ana/$1"
  chown ana:ana "/home/ana/$1"; chmod 600 "/home/ana/$1"
}

# ------------------------------------------------------ the lab's certificates
# One certificate authority for the whole lab, and a certificate per device
# signed by it. ana's programs check against it and never turn checking off:
# /home/ana/lab-ca.pem is the file they name.
build_ca() {
  local d=$LAB/ca
  mkdir -p "$d"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/O=Lab/CN=Lab Root CA" \
    -keyout "$d/ca.key" -out "$d/ca.pem" 2>/dev/null
  for h in $ROUTERS nc1 netbox tickets; do
    local a; a=$(addr_of "$h")
    openssl req -newkey rsa:2048 -nodes -subj "/CN=$h.example.net" \
      -keyout "$d/$h.key" -out "$d/$h.csr" 2>/dev/null
    printf 'subjectAltName=DNS:%s.example.net,DNS:%s,IP:%s\nextendedKeyUsage=serverAuth\n' "$h" "$h" "$a" > "$d/$h.ext"
    openssl x509 -req -in "$d/$h.csr" -CA "$d/ca.pem" -CAkey "$d/ca.key" -CAcreateserial \
      -days 825 -extfile "$d/$h.ext" -out "$d/$h.pem" 2>/dev/null
  done
  install -o ana -g ana -m 644 "$d/ca.pem" /home/ana/lab-ca.pem
}

# ------------------------------------------- the routers' API, from lesson 2
build_devapi() {
  [ -f "$HERE/devapid.py" ] || { say "devapi: skipped, no devapid.py yet (lesson 2)"; return 0; }
  install -D -m 755 "$HERE/devapid.py" /opt/netlab/devapid.py
  for r in $ROUTERS; do
    mkdir -p "$LAB/$r/etc/devapi"
    cp "$LAB/ca/$r.pem" "$LAB/ca/$r.key" "$LAB/$r/etc/devapi/"
    cat > "$LAB/$r/etc/devapi/devapi.json" <<C
{"hostname": "$r", "address": "$(addr_of "$r")",
 "cert": "/etc/devapi/$r.pem", "key": "/etc/devapi/$r.key",
 "users": {"netops": {"password": "$NETOPS_PASSWORD", "role": "read-write"},
           "audit":  {"password": "$AUDIT_PASSWORD", "role": "read-only"}}}
C
    chmod 600 "$LAB/$r/etc/devapi/"*
    on "$r" root "setsid $VENV/bin/python /opt/netlab/devapid.py </dev/null >>/var/log/devapi.err 2>&1 &"
  done
  WAIT+=" 192.0.2.11:443 192.0.2.12:443 192.0.2.13:443 192.0.2.11:9339 192.0.2.12:9339 192.0.2.13:9339"
  say "devapi: started on core1, edge1 and edge2"
}

# ------------------------------------------------- nc1, from lesson 3
# nc1 has no forwarding plane at all. Its configuration is a document Clixon
# holds, checks against YANG (ietf-interfaces, ietf-ip and iana-if-type, the
# copies pyang ships) and serves over NETCONF on port 830 and RESTCONF on 443.
build_nc1() {
  command -v clixon_backend >/dev/null && [ -f "$HERE/lab_restconf.c" ] ||
    { say "nc1: skipped, no Clixon or no lab_restconf.c yet (lesson 3)"; return 0; }
  local d=$LAB/nc1/etc/clixon v=$LAB/nc1/var/clixon m=$VENV/share/yang/modules
  mkdir -p "$d/yang" "$v" /opt/netlab/restconf
  gcc -shared -fPIC -o /opt/netlab/restconf/lab_restconf.so "$HERE/lab_restconf.c" -lclixon -lcrypto
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
  <CLICON_RESTCONF_DIR>/opt/netlab/restconf</CLICON_RESTCONF_DIR>
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
  on nc1 root 'clixon_backend -f /etc/clixon/nc1.xml -s startup -l f/var/clixon/backend.log'
  sleep 1
  on nc1 root 'setsid clixon_restconf -f /etc/clixon/nc1.xml -l f/var/clixon/restconf.log </dev/null >/dev/null 2>&1 &'
  on nc1 root '/usr/sbin/sshd -f /etc/ssh/sshd_config'
  WAIT+=" 192.0.2.21:443 192.0.2.21:830"
  say "nc1: started"
}

# ------------------------------------------- the service desk, from lesson 7
build_desk() {
  [ -f "$HERE/deskd.py" ] || { say "tickets: skipped, no deskd.py yet (lesson 7)"; return 0; }
  local d=$LAB/tickets
  mkdir -p "$d/etc/deskd" "$d/var/lib/deskd"
  install -D -m 755 "$HERE/deskd.py" /opt/netlab/deskd.py
  cp "$LAB/ca/tickets.pem" "$LAB/ca/tickets.key" "$d/etc/deskd/"
  cat > "$d/etc/deskd/deskd.json" <<C
{"address": "192.0.2.40", "token": "$DESK_TOKEN",
 "cert": "/etc/deskd/tickets.pem", "key": "/etc/deskd/tickets.key"}
C
  on tickets root "setsid $VENV/bin/python /opt/netlab/deskd.py </dev/null >>/var/lib/deskd/deskd.err 2>&1 &"
  secret .desk-token "$DESK_TOKEN"
  WAIT+=" 192.0.2.40:443"
  say "tickets: started"
}

# ---------------------------------------- the NAPALM driver, from lesson 8
build_napalm() {
  [ -f "$HERE/napalm_frr.py" ] || { say "napalm_frr: skipped, no napalm_frr.py yet (lesson 8)"; return 0; }
  install -D -m 644 "$HERE/napalm_frr.py" "$VENV/lib/python3.12/site-packages/napalm_frr/__init__.py"
  say "napalm_frr: installed"
}

# ----------------------------------------------------- NetBox, from lesson 12
# PostgreSQL and Redis run inside the netbox machine. Migrating an empty
# database takes minutes, so the first build keeps a copy of the migrated and
# seeded database in /var/cache/netlab and later builds unpack it.
build_netbox() {
  [ -x "$NETBOX/venv/bin/gunicorn" ] && [ -f "$HERE/netbox_seed.py" ] ||
    { say "netbox: skipped, no NetBox or no netbox_seed.py yet (lesson 12)"; return 0; }
  local d=$LAB/netbox cache=/var/cache/netlab/netbox-pg.tar
  mkdir -p "$d/pg" "$d/run" "$d/redis" /var/cache/netlab
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
    on netbox root "runuser -u postgres -- $pg/initdb -A trust -D $d/pg --locale=C.UTF-8 >/dev/null"
  fi
  on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg -l $d/run/pg.log -o '-k $d/run -c listen_addresses=' start"
  on netbox root "redis-server --bind 127.0.0.1 --port 6379 --dir $d/redis --daemonize yes --logfile $d/redis.log"
  if [ ! -f "$cache" ]; then
    say "netbox: first build, migrating the database (minutes)"
    on netbox root "runuser -u postgres -- psql -q -h $d/run -c \"CREATE USER netbox PASSWORD 'netbox'\" -c 'CREATE DATABASE netbox OWNER netbox'"
    on netbox root "$nb migrate --no-input >/dev/null && $nb collectstatic --no-input >/dev/null"
    cp "$HERE/netbox_seed.py" "$d/seed.py"
    on netbox root "ADMIN_PASSWORD='$NETBOX_ADMIN_PASSWORD' TOKEN_KEY='$NETBOX_TOKEN_KEY' TOKEN='$NETBOX_TOKEN' $nb shell < $d/seed.py"
    on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg stop"
    tar -C "$d" -cf "$cache" pg
    on netbox root "runuser -u postgres -- $pg/pg_ctl -s -D $d/pg -l $d/run/pg.log -o '-k $d/run -c listen_addresses=' start"
  fi
  on netbox root "cd $NETBOX/netbox; setsid $NETBOX/venv/bin/gunicorn --bind 192.0.2.30:443 --workers 3 --certfile $d/netbox.pem --keyfile $d/netbox.key --access-logfile $d/access.log --error-logfile $d/gunicorn.log netbox.wsgi </dev/null >/dev/null 2>&1 &"
  on netbox root "setsid $nb rqworker high default low </dev/null >>$d/rqworker.log 2>&1 &"
  secret .netbox-token "nbt_$NETBOX_TOKEN_KEY.$NETBOX_TOKEN"
  WAIT+=" 192.0.2.30:443"
  say "netbox: started"
}

# ------------------------------------------------- the SDN corner, lesson 15
# Open vSwitch runs inside sw1 with the userspace datapath (datapath_type=netdev),
# so nothing is loaded into your machine's kernel; it forwards the same OpenFlow,
# slower. br0 starts with fail_mode=secure and no controller, so it forwards
# nothing until the lesson gives it flows.
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
  on sw1 root 'ovsdb-server /etc/openvswitch/conf.db --remote=punix:/run/openvswitch/db.sock -vconsole:off \
      --pidfile --detach --log-file=/var/log/openvswitch/ovsdb-server.log
    ovs-vsctl --no-wait init
    ovs-vswitchd --pidfile --detach -vconsole:off --log-file=/var/log/openvswitch/ovs-vswitchd.log
    ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev fail_mode=secure \
      protocols=OpenFlow13 other-config:datapath-id=0000000000000001
    for i in 1 2 3; do ovs-vsctl add-port br0 p$i -- set interface p$i ofport_request=$i; done'
  # ana works the switch as an operator would, without root: the sockets are
  # her group's. A real switch would give her a role; this is the lab's.
  on sw1 root 'chgrp -R ana /run/openvswitch && chmod -R g+rwX /run/openvswitch'
  say "sw1: started"
}

# The lab is up when everything a lesson talks to answers: both OSPF
# adjacencies on core1 are Full, each branch has learnt the other's LAN, and
# every service that was started accepts a connection.
wait_ready() {
  local i a
  for i in $(seq 120); do
    [ "$(on core1 root 'vtysh -c "show ip ospf neighbor"' | grep -c Full)" = 2 ] && break
    sleep 1
  done
  for i in $(seq 120); do
    on edge1 root 'ip route show 203.0.113.64/26' | grep -q via &&
      on edge2 root 'ip route show 203.0.113.0/26' | grep -q via && break
    sleep 1
  done
  for a in $WAIT; do
    for i in $(seq 120); do
      on ctl root "timeout 1 bash -c '</dev/tcp/${a%:*}/${a#*:}'" 2>/dev/null && break
      [ "$i" = 120 ] && say "nothing answers on $a"
      sleep 1
    done
  done
  say "up: OSPF is Full and every service above answers"
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
  if ip netns list | grep -qw ctl; then say "already up; reset rebuilds it"; return 0; fi
  down    # whatever a restart or an interrupted build left behind
  WAIT=""
  operator
  build_net
  hostfiles
  build_ca
  build_frr
  build_ssh
  build_devapi
  build_nc1
  build_desk
  build_napalm
  build_netbox
  build_sdn
  wait_ready
}

case ${1:-} in
  up)    up ;;
  down)  need; down ;;
  reset) need; down; up ;;
  enter) need; on "${2:?which host?}" "${3:-ana}" "${4:-}" ;;
  *) sed -n '2,31p' "$0"; exit 2 ;;
esac
```

Torne-o executável e construa a rede:

```sh
chmod +x ~/netlab/netlab.sh
sudo ~/netlab/netlab.sh up
```

A primeira construção na máquina deste curso, cronometrada:

```
ubuntu@netlab:~$ time sudo ~/netlab/netlab.sh up
netlab: devapi: skipped, no devapid.py yet (lesson 2)
netlab: nc1: skipped, no Clixon or no lab_restconf.c yet (lesson 3)
netlab: tickets: skipped, no deskd.py yet (lesson 7)
netlab: napalm_frr: skipped, no napalm_frr.py yet (lesson 8)
netlab: netbox: skipped, no NetBox or no netbox_seed.py yet (lesson 12)
netlab: sw1: started
netlab: up: OSPF is Full and every service above answers

real	0m25.955s
user	0m5.231s
sys	0m1.078s
```

Vinte e cinco segundos, e a maior parte é espera: o `wait_ready` no fim do script segura o prompt
até o OSPF formar as duas adjacências e cada filial aprender a rede da outra. **Cinco linhas dizem
`skipped`, e isso está certo depois da aula 1.** Cada uma nomeia o programa que está esperando e a
aula que o entrega a você. Salve o programa ao lado do `netlab.sh`, reconstrua com `reset`, e a
linha passa a dizer `started`.

O `enter` abre um shell numa das máquinas do laboratório, como `ana` a menos que você nomeie outra
pessoa. No `ctl` o prompt muda, e dali os roteadores estão a um nome de distância:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh enter ctl
ana@ctl:~$ hostname
ctl
ana@ctl:~$ ssh netops@edge1 "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
203.0.113.251     1 Full/-          13.663s           36.335s 198.51.100.1    eth1:198.51.100.2                    0     0     0

ana@ctl:~$ exit
exit
ubuntu@netlab:~$ 
```

A `ana` é a engenheira cujas sessões estas aulas mostram, e o `netlab.sh` criou a conta dela na
máquina virtual. **A home dela no `ctl` é a `/home/ana` de verdade da máquina virtual**, então o
que você escreve ali numa aula continua lá na seguinte, aconteça o que acontecer com o laboratório.
Todas as outras máquinas do laboratório são reconstruídas do zero a cada vez.

Dois hábitos deixam o seu terminal parecido com o das aulas:

- **Comece toda aula com `sudo ~/netlab/netlab.sh reset`.** Ele derruba o laboratório e o constrói
  de novo, o que leva os roteadores de volta à configuração com que ligam. As transcrições de toda
  aula foram feitas num laboratório construído exatamente assim, e uma mudança deixada num roteador
  pela aula anterior apareceria na saída desta.
- **Digite no prompt `ana@ctl:~$` o que as aulas digitam ali**, e no `ubuntu@netlab:~$` o que elas
  digitam ali. O segundo é a própria máquina virtual, onde o software é instalado e o laboratório é
  construído; o primeiro fica dentro do laboratório, que não alcança a internet.
