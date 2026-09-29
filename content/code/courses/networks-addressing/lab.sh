#!/usr/bin/env bash
# The networks every transcript in this course was recorded on.
#
# IT IS ONE LINUX COMPUTER. Each device below, a PC, a switch or a router, is a
# network namespace: its own interfaces, addresses, routes, bridges and
# firewall, and its own hostname. A cable is a virtual Ethernet pair. A switch
# is a Linux bridge inside its own namespace, so it learns MAC addresses,
# floods, tags VLANs and runs spanning tree the way the kernel's bridge does. A
# router is a namespace with forwarding switched on, and the routing protocols
# are FRR, one copy of each daemon per router.
#
# THE CABLES CARRY NO DELAY. Every round trip in the lessons is one computer
# talking to itself, and the prose says so wherever a time is read. The
# machine the lessons were recorded on was itself a virtual machine with no
# hardware acceleration, so times are slower than a laptop would print, and
# they are a measurement of that machine and not of a network.
#
# NOTHING HERE REACHES THE REAL INTERNET. The addresses are private ranges
# (RFC 1918), the blocks reserved for documentation (RFC 5737: 192.0.2.0/24,
# 198.51.100.0/24, 203.0.113.0/24; RFC 3849: 2001:db8::/32) and the autonomous
# system numbers reserved for documentation (RFC 5398: 64496 to 64511), which
# is why they are safe to print.
#
# A LESSON BUILDS ONE SCENARIO. Each captures.sh starts with `lab.sh up NAME`,
# which tears down whatever was there and builds that scenario from nothing,
# so a transcript never depends on what an earlier lesson left behind.
#
#   sudo bash lab.sh up SCENARIO     build one (see the scenario_ functions)
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'
#   sudo bash lab.sh list            the scenarios
#
# Recorded on Ubuntu 24.04 (kernel 6.8), with the packages in need().
set -euo pipefail

LAB=/run/lab
TZ_LAB=America/Sao_Paulo

need() {
  local missing=() p
  for p in iproute2 bridge-utils ethtool frr tcpdump iputils-ping iputils-arping traceroute \
           nftables conntrack isc-dhcp-server isc-dhcp-client isc-dhcp-relay radvd ndisc6 \
           ipcalc sipcalc wireguard-tools lldpd python3 sudo; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  modprobe -a 8021q bonding bridge veth wireguard 2>/dev/null || true
  id ana >/dev/null 2>&1 || { echo "create the user first: useradd -m -s /bin/bash ana" >&2; exit 1; }
  [ -f /etc/sudoers.d/lab-ana ] || { echo 'ana ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/lab-ana; chmod 440 /etc/sudoers.d/lab-ana; }
}

# A MAC address that is the same every time the lab is built: 02, which marks
# it as locally administered rather than burnt in by a manufacturer, and five
# bytes of a hash of the device and interface names.
mac() { printf '02:%s' "$(printf '%s-%s' "$1" "$2" | md5sum | cut -c1-10 | sed 's/../&:/g; s/:$//')"; }

# ------------------------------------------------------------------ devices
node() {  # node NAME [router]
  local n=$1
  ip netns del "$n" 2>/dev/null || true   # left over from a lab nobody took down
  ip netns add "$n"
  ip -n "$n" link set lo up
  echo "$n" >> "$LAB/nodes"
  mkdir -p "/etc/netns/$n" "$LAB/$n/dhcp"
  printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$n" > "/etc/netns/$n/hosts"
  printf 'nameserver 127.0.0.1\n' > "/etc/netns/$n/resolv.conf"
  ip netns exec "$n" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  # A linked address stays unused until the kernel has checked nobody else has
  # it. Real networks wait too; the lab does not, so a capture never catches an
  # address still "tentative".
  ip netns exec "$n" sysctl -qw net.ipv6.conf.all.accept_dad=0 net.ipv6.conf.default.accept_dad=0
  # A route over a link that is down is not used, as on a router.
  ip netns exec "$n" sysctl -qw net.ipv4.conf.all.ignore_routes_with_linkdown=1 \
    net.ipv4.conf.default.ignore_routes_with_linkdown=1
  if [ "${2:-}" = router ]; then
    ip netns exec "$n" sysctl -qw net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1
    # A router answers a traceroute from the interface the probe came in by,
    # as most routers do, rather than from whichever one the answer leaves by.
    ip netns exec "$n" sysctl -qw net.ipv4.icmp_errors_use_inbound_ifaddr=1
    # Linux drops a packet whose source it has no route back to (loose
    # reverse-path filtering). A router forwards it unless told otherwise, and
    # lessons 14 and 15 are about exactly the packets that have no way back.
    ip netns exec "$n" sysctl -qw net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.default.rp_filter=0
  fi
}

link() {  # link NODE1 IF1 NODE2 IF2 : one cable
  local tmp1="t$RANDOM$RANDOM" tmp2="u$RANDOM$RANDOM"
  ip link add "$tmp1" type veth peer "$tmp2"
  ip link set "$tmp1" netns "$1"; ip -n "$1" link set "$tmp1" name "$2"
  ip link set "$tmp2" netns "$3"; ip -n "$3" link set "$tmp2" name "$4"
  ip -n "$1" link set "$2" address "$(mac "$1" "$2")"
  ip -n "$3" link set "$4" address "$(mac "$3" "$4")"
  ip -n "$1" link set "$2" up
  ip -n "$3" link set "$4" up
}

addr() { ip -n "$1" addr add "$3" dev "$2"; }          # addr NODE IF ADDRESS/PREFIX
gw()   { ip -n "$1" route add default via "$2"; }       # gw NODE GATEWAY
host() { printf '%s %s\n' "$2" "$3" >> "/etc/netns/$1/hosts"; }  # host NODE ADDRESS NAME

# A switch: a namespace holding one bridge, br0, with every listed interface
# as a port. Options go straight to `ip link add br0 type bridge`.
switch() {  # switch NAME "PORTS" [bridge options]
  local n=$1 ports=$2; shift 2
  ip -n "$n" link add br0 type bridge "$@"
  ip -n "$n" link set br0 address "$(mac "$n" br0)"
  local p; for p in $ports; do ip -n "$n" link set "$p" master br0; done
  ip -n "$n" link set br0 up
}

# ------------------------------------------------------------- daemons
# Every daemon the lab starts writes its pid under $LAB, and down() kills
# those pids and nothing else.
daemon() {  # daemon NODE PIDFILE COMMAND...
  local n=$1 pf=$2; shift 2
  ip netns exec "$n" setsid "$@" </dev/null >"$LAB/$n/$(basename "$pf").log" 2>&1 &
  echo $! > "$pf"
}

# FRR: one zebra and one of each routing daemon per router, told apart by
# FRR's own -N option. vtysh reaches the right one because exec_on() gives
# every shell on that router a vtysh that adds -N for it.
frr() {  # frr NODE  (configuration on stdin)
  local n=$1 d
  install -d -o frr -g frr "/etc/frr/$n" "/var/run/frr/$n"
  cat > "/etc/frr/$n/frr.conf"
  : > "/etc/frr/$n/vtysh.conf"
  chown frr:frr "/etc/frr/$n/frr.conf" "/etc/frr/$n/vtysh.conf"
  local daemons="zebra staticd ${FRR_EXTRA:-}"   # FRR_EXTRA: daemons to start whatever the file says
  grep -q '^router ospf'  "/etc/frr/$n/frr.conf" && daemons+=" ospfd"
  grep -q '^router rip'   "/etc/frr/$n/frr.conf" && daemons+=" ripd"
  grep -q '^router bgp'   "/etc/frr/$n/frr.conf" && daemons+=" bgpd"
  grep -q '^router eigrp' "/etc/frr/$n/frr.conf" && daemons+=" eigrpd"
  for d in $daemons; do
    ip netns exec "$n" "/usr/lib/frr/$d" -d -N "$n" -F traditional \
      -f "/etc/frr/$n/frr.conf" -i "/var/run/frr/$n/$d.pid" 2>>"$LAB/$n/frr.log"
    echo "/var/run/frr/$n/$d.pid" >> "$LAB/pidfiles"
  done
}

lldp() {  # lldp NODE : an LLDP agent announcing this device to its neighbours
  # its own hostname, which is what it announces as the device's name
  daemon "$1" "$LAB/$1/lldpd.pid" unshare --uts sh -c "hostname $1; exec lldpd -d -u $LAB/$1/lldpd.socket -p $LAB/$1/lldpd.pidfile"
  echo "$LAB/$1/lldpd.pid" >> "$LAB/pidfiles"
}

web() {  # web NODE ADDRESS : a web server whose page says which machine it is
  mkdir -p "$LAB/$1/www"
  printf 'served by %s\n' "$1" > "$LAB/$1/www/index.html"
  daemon "$1" "$LAB/$1/web.pid" python3 -m http.server 80 --bind "$2" --directory "$LAB/$1/www"
  echo "$LAB/$1/web.pid" >> "$LAB/pidfiles"
  wait_for 60 bash -c "ip netns exec $1 ss -Htln 'sport = :80' | grep -q LISTEN"
}

wait_for() {  # wait_for SECONDS COMMAND... : until it succeeds, or say so
  local t=$1; shift
  for _ in $(seq "$t"); do "$@" >/dev/null 2>&1 && return 0; sleep 1; done
  echo "lab: waited ${t}s and this never succeeded: $*" >&2; return 1
}

exec_on() {  # exec_on HOST USER COMMAND
  local h=$1 u=$2 c=$3
  local shim="vtysh() { command vtysh -N $h \"\$@\"; }; lldpcli() { command lldpcli -u $LAB/$h/lldpd.socket \"\$@\"; }; export -f vtysh lldpcli 2>/dev/null;"
  # Each device keeps its DHCP leases in its own /var/lib/dhcp, as a separate
  # machine would; ip netns exec already gives every command its own mounts.
  ip netns exec "$h" unshare --uts bash -c '
    hostname "$1"
    mount --bind '"$LAB"'/"$1"/dhcp /var/lib/dhcp
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$shim $c"
}

down() {
  local f n
  if [ -f "$LAB/pidfiles" ]; then
    while read -r f; do [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null || true; done < "$LAB/pidfiles"
    sleep 1
  fi
  if [ -f "$LAB/nodes" ]; then
    # anything still running inside a device, such as a DHCP client renewing
    while read -r n; do ip netns pids "$n" 2>/dev/null | xargs -r kill 2>/dev/null || true; done < "$LAB/nodes"
    sleep 1
    while read -r n; do
      ip netns del "$n" 2>/dev/null || true
      rm -rf "/etc/netns/$n" "/etc/frr/$n" "/var/run/frr/$n"
    done < "$LAB/nodes"
  fi
  rm -rf "$LAB"
}

up() {
  local s=$1
  declare -F "scenario_$s" >/dev/null || { echo "no scenario called $s; try: lab.sh list" >&2; exit 1; }
  need; down
  mkdir -p "$LAB"; : > "$LAB/nodes"; : > "$LAB/pidfiles"
  echo "$s" > "$LAB/scenario"
  "scenario_$s"
}

# =================================================================== scenarios

# office: four PCs on one switch, a router that is also the firewall and does
# NAT, the provider, and a load balancer in front of two web servers.
#
#   pc1 pc2 pc3 srv --- sw1 --- r1 === isp --- lb --- web1, web2
#   10.20.10.0/24               203.0.113.0/30   192.0.2.0/24   10.99.0.0/24
scenario_office() {
  local n
  for n in pc1 pc2 pc3 srv sw1 lb web1 web2; do node $n; done
  node r1 router; node isp router
  link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link pc3 eth0 sw1 p3
  link srv eth0 sw1 p4; link r1 eth0 sw1 p8
  switch sw1 "p1 p2 p3 p4 p8"
  addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr pc3 eth0 10.20.10.23/24
  addr srv eth0 10.20.10.10/24; addr r1 eth0 10.20.10.1/24
  for n in pc1 pc2 pc3 srv; do gw $n 10.20.10.1; done
  link r1 eth1 isp eth0
  addr r1 eth1 203.0.113.2/30; addr isp eth0 203.0.113.1/30; gw r1 203.0.113.1
  link isp eth1 lb eth0
  addr isp eth1 192.0.2.1/24; addr lb eth0 192.0.2.80/24; gw lb 192.0.2.1
  link lb eth1 web1 eth0; link lb eth2 web2 eth0
  addr lb eth1 10.99.0.1/28; addr web1 eth0 10.99.0.11/28
  addr lb eth2 10.99.0.17/28; addr web2 eth0 10.99.0.18/28
  gw web1 10.99.0.1; gw web2 10.99.0.17
  ip netns exec lb sysctl -qw net.ipv4.ip_forward=1
  web web1 10.99.0.11; web web2 10.99.0.18; web srv 10.20.10.10
  # The router: every office machine leaves with its one public address, and
  # nothing from outside starts a conversation inside.
  ip netns exec r1 nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
table inet filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related counter accept
    iifname "eth0" oifname "eth1" counter accept
    counter comment "everything else: dropped"
  }
}
NFT
  # The load balancer: one public address, and each new connection goes to the
  # next web server in turn.
  ip netns exec lb nft -f - <<'NFT'
table ip lb {
  chain prerouting {
    type nat hook prerouting priority dstnat;
    ip daddr 192.0.2.80 tcp dport 80 dnat to numgen inc mod 2 map { 0 : 10.99.0.11, 1 : 10.99.0.18 }
  }
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname { "eth1", "eth2" } masquerade
  }
}
NFT
  for n in pc1 pc2 pc3 srv r1; do
    host $n 10.20.10.21 pc1; host $n 10.20.10.22 pc2; host $n 10.20.10.23 pc3
    host $n 10.20.10.10 srv; host $n 10.20.10.1 r1
  done
}

# ring: four routers in a ring, each cable its own /30, and a PC behind r1 and
# behind r2. OSPF finds the paths, with its timers cut to a hello every second
# so a broken cable is noticed in four seconds instead of forty; lesson 16 is
# where those timers are explained. `mesh` is the same ring with the two
# diagonals added, so every router has a cable to every other one.
#
#        pc1    pc2               10.20.0.0/30   r1-r2      10.20.0.8/30   r3-r4
#         |      |                10.20.0.4/30   r2-r3      10.20.0.12/30  r4-r1
#   r4 -- r1 -- r2                10.20.1.0/24   behind r1  10.20.2.0/24   behind r2
#    |           |                mesh adds      10.20.0.16/30 r1-r3, 10.20.0.20/30 r2-r4
#    +--- r3 ----+
ospf_p2p() {  # ospf_p2p NODE ROUTER-ID "INTERFACES" : OSPF on every 10.20 interface
  local n=$1 id=$2 i
  {
    echo "hostname $n"
    for i in $3; do
      printf 'interface %s\n ip ospf network point-to-point\n ip ospf hello-interval 1\n ip ospf dead-interval 4\n' "$i"
    done
    printf 'router ospf\n ospf router-id %s\n network 10.20.0.0/16 area 0\n' "$id"
  } | frr "$n"
}
ring_build() {
  local n
  for n in r1 r2 r3 r4; do node $n router; done
  node pc1; node pc2
  link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
  link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
  link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
  link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
  link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
  link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
}
scenario_ring() {
  ring_build
  ospf_p2p r1 10.255.0.1 "eth1 eth4"; ospf_p2p r2 10.255.0.2 "eth1 eth2"
  ospf_p2p r3 10.255.0.3 "eth2 eth3"; ospf_p2p r4 10.255.0.4 "eth3 eth4"
  wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
}
scenario_mesh() {
  ring_build
  link r1 eth5 r3 eth5; addr r1 eth5 10.20.0.17/30; addr r3 eth5 10.20.0.18/30
  link r2 eth6 r4 eth6; addr r2 eth6 10.20.0.21/30; addr r4 eth6 10.20.0.22/30
  ospf_p2p r1 10.255.0.1 "eth1 eth4 eth5"; ospf_p2p r2 10.255.0.2 "eth1 eth2 eth6"
  ospf_p2p r3 10.255.0.3 "eth2 eth3 eth5"; ospf_p2p r4 10.255.0.4 "eth3 eth4 eth6"
  wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
}

# sites: a head office and a branch in another city, each with a router that
# does NAT, joined only by the provider. The branch is reached over the
# internet or, once lesson 4 builds it, through a WireGuard tunnel.
#
#   pc1 --- rhq ==== isp ==== rbr --- pc2
#   10.20.10.0/24  203.0.113.0/30  198.51.100.0/30  10.30.10.0/24
#
# THE TUNNEL KEYS ARE WRITTEN HERE, and that is the only reason the lesson's
# `wg show` prints the same thing on every run. They protect nothing: anybody
# can read them in this file. Never copy a key from a lesson into a real
# tunnel; `wg genkey` makes a new one.
WG_HQ_KEY='GDNn9hZF8EMa3dOdNriCkv7wUSNKPmiNFnLAFss/320='
WG_BR_KEY='+NDqNEgyW6ovPD5VS4cet2/zHvQ8YDbzo42zM27XtHc='
scenario_sites() {
  local n
  node pc1; node pc2; node rhq router; node rbr router; node isp router
  link pc1 eth0 rhq eth0; addr pc1 eth0 10.20.10.21/24; addr rhq eth0 10.20.10.1/24; gw pc1 10.20.10.1
  link pc2 eth0 rbr eth0; addr pc2 eth0 10.30.10.22/24; addr rbr eth0 10.30.10.1/24; gw pc2 10.30.10.1
  link rhq eth1 isp eth0; addr rhq eth1 203.0.113.2/30;  addr isp eth0 203.0.113.1/30;  gw rhq 203.0.113.1
  link rbr eth1 isp eth1; addr rbr eth1 198.51.100.2/30; addr isp eth1 198.51.100.1/30; gw rbr 198.51.100.1
  for n in rhq rbr; do
    ip netns exec $n nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
  done
  install -m 600 /dev/null "$LAB/rhq/wg.key"; echo "$WG_HQ_KEY" > "$LAB/rhq/wg.key"
  install -m 600 /dev/null "$LAB/rbr/wg.key"; echo "$WG_BR_KEY" > "$LAB/rbr/wg.key"
}

# campus: the three-tier design of lesson 6. Two core routers, two
# distribution routers each cabled to both cores, and an access switch under
# each distribution router with one PC on it. OSPF with lesson 3's fast
# timers; LLDP on every device, so each can say who is at the other end of
# each cable.
#
#        c1 ------------- c2               links: 10.20.0.0/24, one /30 each
#        |  \           / |                pc1's LAN: 10.20.11.0/24 (gateway d1)
#        |    \       /   |                pc2's LAN: 10.20.12.0/24 (gateway d2)
#        d1 -----\ /----- d2
#        |               |
#        a1              a2
#        |               |
#        pc1             pc2
scenario_campus() {
  local n
  for n in c1 c2 d1 d2; do node $n router; done
  for n in a1 a2 pc1 pc2; do node $n; done
  link c1 eth1 c2 eth1; addr c1 eth1 10.20.0.1/30;  addr c2 eth1 10.20.0.2/30
  link c1 eth2 d1 eth1; addr c1 eth2 10.20.0.5/30;  addr d1 eth1 10.20.0.6/30
  link c1 eth3 d2 eth1; addr c1 eth3 10.20.0.9/30;  addr d2 eth1 10.20.0.10/30
  link c2 eth2 d1 eth2; addr c2 eth2 10.20.0.13/30; addr d1 eth2 10.20.0.14/30
  link c2 eth3 d2 eth2; addr c2 eth3 10.20.0.17/30; addr d2 eth2 10.20.0.18/30
  link d1 eth0 a1 p24; link pc1 eth0 a1 p1; switch a1 "p1 p24"
  link d2 eth0 a2 p24; link pc2 eth0 a2 p1; switch a2 "p1 p24"
  addr d1 eth0 10.20.11.1/24; addr pc1 eth0 10.20.11.21/24; gw pc1 10.20.11.1
  addr d2 eth0 10.20.12.1/24; addr pc2 eth0 10.20.12.22/24; gw pc2 10.20.12.1
  ospf_p2p c1 10.255.0.1 "eth1 eth2 eth3"; ospf_p2p c2 10.255.0.2 "eth1 eth2 eth3"
  ospf_p2p d1 10.255.0.11 "eth1 eth2";     ospf_p2p d2 10.255.0.12 "eth1 eth2"
  for n in c1 c2 d1 d2 a1 a2 pc1 pc2; do lldp $n; done
  wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.12.22
}

# dualstack: an office LAN that speaks IPv4 and IPv6 at once. r1 announces
# the office's IPv6 prefix with radvd and the PCs build their own addresses
# from it; srv is given its IPv6 address by hand, as a server usually is.
#
#   pc1 pc2 srv --- sw1 --- r1 === isp --- web
#   10.20.10.0/24           203.0.113.0/30        192.0.2.0/24
#   2001:db8:20:10::/64     2001:db8:ffff::/64    2001:db8:99::/64
scenario_dualstack() {
  local n
  for n in pc1 pc2 srv sw1 web; do node $n; done
  node r1 router; node isp router
  link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link srv eth0 sw1 p4; link r1 eth0 sw1 p8
  switch sw1 "p1 p2 p4 p8"
  addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr srv eth0 10.20.10.10/24
  addr r1 eth0 10.20.10.1/24; addr r1 eth0 2001:db8:20:10::1/64
  addr srv eth0 2001:db8:20:10::10/64
  ip netns exec srv sysctl -qw net.ipv6.conf.eth0.autoconf=0   # its one address is the one it was given
  for n in pc1 pc2 srv; do gw $n 10.20.10.1; done
  ip -n srv -6 route add default via 2001:db8:20:10::1
  link r1 eth1 isp eth0
  addr r1 eth1 203.0.113.2/30; addr isp eth0 203.0.113.1/30; gw r1 203.0.113.1
  addr r1 eth1 2001:db8:ffff::2/64; addr isp eth0 2001:db8:ffff::1/64
  ip -n r1 -6 route add default via 2001:db8:ffff::1
  ip -n isp -6 route add 2001:db8:20::/48 via 2001:db8:ffff::2
  link isp eth1 web eth0
  addr isp eth1 192.0.2.1/24; addr web eth0 192.0.2.80/24; gw web 192.0.2.1
  addr isp eth1 2001:db8:99::1/64; addr web eth0 2001:db8:99::80/64
  ip -n web -6 route add default via 2001:db8:99::1
  ip netns exec r1 nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
  cat > "$LAB/r1/radvd.conf" <<'RA'
interface eth0 {
  AdvSendAdvert on;
  MinRtrAdvInterval 30;
  MaxRtrAdvInterval 100;
  prefix 2001:db8:20:10::/64 {
    AdvOnLink on;
    AdvAutonomous on;
  };
};
RA
  daemon r1 "$LAB/r1/radvd.pid" radvd -n -C "$LAB/r1/radvd.conf" -p "$LAB/r1/radvd.pidfile" -m stderr
  echo "$LAB/r1/radvd.pid" >> "$LAB/pidfiles"
  web web '::'
  for n in pc1 pc2 srv r1; do
    host $n 10.20.10.10 srv; host $n 2001:db8:20:10::10 srv
    host $n 192.0.2.80 web; host $n 2001:db8:99::80 web
  done
}

# dhcp: an office whose PCs get their addresses from a DHCP server. srv
# serves the office LAN and, through a relay on r1, a second floor on its own
# subnet. prn is a printer with a reservation. rogue is a PC that a lesson
# turns into a second DHCP server nobody asked for.
#
#   pc1 pc2 prn rogue srv --- sw1 --- r1 --- pc4
#   10.20.10.0/24 (srv .10, r1 .1)       10.20.20.0/24 (r1 .1)
dhcpd_on() {  # dhcpd_on NODE IFACE CONFIG-FILE
  touch "$LAB/$1/dhcp/dhcpd.leases"
  daemon "$1" "$LAB/$1/dhcpd.pid" unshare --mount sh -c \
    "mount --bind $LAB/$1/dhcp /var/lib/dhcp; exec dhcpd -4 -f -d -cf $3 -pf $LAB/$1/dhcpd.pidfile $2"
  echo "$LAB/$1/dhcpd.pid" >> "$LAB/pidfiles"
}
scenario_dhcp() {
  local n
  for n in pc1 pc2 prn rogue srv sw1 pc4; do node $n; done
  node r1 router
  link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link prn eth0 sw1 p3; link rogue eth0 sw1 p5
  link srv eth0 sw1 p4; link r1 eth0 sw1 p8
  switch sw1 "p1 p2 p3 p4 p5 p8"
  link r1 eth2 pc4 eth0
  addr srv eth0 10.20.10.10/24; addr r1 eth0 10.20.10.1/24; addr r1 eth2 10.20.20.1/24
  gw srv 10.20.10.1
  cat > "$LAB/srv/dhcpd.conf" <<CONF
# the office's DHCP server
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 10.20.10.10;

subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.100 10.20.10.199;
  option routers 10.20.10.1;
}

subnet 10.20.20.0 netmask 255.255.255.0 {
  range 10.20.20.100 10.20.20.199;
  option routers 10.20.20.1;
}

host prn {
  hardware ethernet $(mac prn eth0);
  fixed-address 10.20.10.50;
}
CONF
  dhcpd_on srv eth0 "$LAB/srv/dhcpd.conf"
}
# rogue: a second DHCP server on the office LAN, answering with its own idea
# of the gateway. Started by lesson 10 and never by a scenario.
rogue_dhcp() {
  addr rogue eth0 10.20.10.66/24
  cat > "$LAB/rogue/dhcpd.conf" <<'CONF'
default-lease-time 600;
subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.200 10.20.10.220;
  option routers 10.20.10.66;
  option domain-name-servers 10.20.10.66;
}
CONF
  dhcpd_on rogue eth0 "$LAB/rogue/dhcpd.conf"
}

# plan: one /24 cut into subnets of different sizes (lesson 13's plan), each
# on its own interface of r1, and r2 upstream holding one route for all of
# them.
#
#   sales1 --(10.20.32.0/25)---+
#   eng1   --(10.20.32.128/26)-+- r1 --(10.20.32.224/30)-- r2 --(10.20.99.0/24)-- hq1
#   ops1   --(10.20.32.192/27)-+
scenario_plan() {
  local n
  for n in sales1 eng1 ops1 hq1; do node $n; done
  node r1 router; node r2 router
  link sales1 eth0 r1 eth1; addr sales1 eth0 10.20.32.10/25;  addr r1 eth1 10.20.32.1/25
  link eng1 eth0 r1 eth2;   addr eng1 eth0 10.20.32.140/26;  addr r1 eth2 10.20.32.129/26
  link ops1 eth0 r1 eth3;   addr ops1 eth0 10.20.32.200/27;  addr r1 eth3 10.20.32.193/27
  gw sales1 10.20.32.1; gw eng1 10.20.32.129; gw ops1 10.20.32.193
  link r1 eth0 r2 eth0; addr r1 eth0 10.20.32.225/30; addr r2 eth0 10.20.32.226/30
  gw r1 10.20.32.226
  link r2 eth1 hq1 eth0; addr r2 eth1 10.20.99.1/24; addr hq1 eth0 10.20.99.10/24; gw hq1 10.20.99.1
  ip -n r2 route add 10.20.32.0/24 via 10.20.32.225
}

# paths: a router with two ways out. r1 is cabled to ra and to rb, and both
# of those sit on the same far network, where far1 and far2 live. Nothing is
# routed dynamically: lesson 14 writes every route by hand, and FRR runs on
# r1 with an empty configuration so its route table can be read beside the
# kernel's.
#
#                 +-- ra (10.20.1.0/30) --+
#   pc1 --- r1 ---+                       +--- 10.30.0.0/16: far1 .5.10, far2 .7.10
#   10.20.10.0/24 +-- rb (10.20.2.0/30) --+    (ra .0.1, rb .0.2)
scenario_paths() {
  local n
  for n in pc1 sw9 far1 far2; do node $n; done
  node r1 router; node ra router; node rb router
  link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.10.21/24; addr r1 eth0 10.20.10.1/24; gw pc1 10.20.10.1
  link r1 eth1 ra eth0; addr r1 eth1 10.20.1.1/30; addr ra eth0 10.20.1.2/30
  link r1 eth2 rb eth0; addr r1 eth2 10.20.2.1/30; addr rb eth0 10.20.2.2/30
  link ra eth1 sw9 p1; link rb eth1 sw9 p2; link far1 eth0 sw9 p3; link far2 eth0 sw9 p4
  switch sw9 "p1 p2 p3 p4"
  addr ra eth1 10.30.0.1/16; addr rb eth1 10.30.0.2/16
  addr far1 eth0 10.30.5.10/16; addr far2 eth0 10.30.7.10/16
  gw far1 10.30.0.1; gw far2 10.30.0.1
  ip -n ra route add 10.20.0.0/16 via 10.20.1.1
  ip -n rb route add 10.20.0.0/16 via 10.20.2.1
  echo "hostname r1" | frr r1
}

# chain: three routers in a line with a spare cable from r1 to r3, a PC at
# each end, and no routes but the connected ones. Lesson 15 writes them.
#
#   pc1 --- r1 --(10.20.12.0/30)-- r2 --(10.20.23.0/30)-- r3 --- pc3
#   10.20.1.0/24 \_________(10.20.13.0/30, the spare)_____/  10.20.3.0/24
scenario_chain() {
  local n
  node pc1; node pc3
  for n in r1 r2 r3; do node $n router; done
  link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
  link pc3 eth0 r3 eth0; addr pc3 eth0 10.20.3.10/24; addr r3 eth0 10.20.3.1/24; gw pc3 10.20.3.1
  link r1 eth1 r2 eth1; addr r1 eth1 10.20.12.1/30; addr r2 eth1 10.20.12.2/30
  link r2 eth2 r3 eth2; addr r2 eth2 10.20.23.1/30; addr r3 eth2 10.20.23.2/30
  link r1 eth3 r3 eth3; addr r1 eth3 10.20.13.1/30; addr r3 eth3 10.20.13.2/30
}

# igp: lesson 3's ring of four routers, with no routing protocol configured.
# FRR runs on every router with only its hostname, and every daemon lesson 16
# needs is started; the lesson types RIP, OSPF and EIGRP into it.
scenario_igp() {
  ring_build
  local n
  for n in r1 r2 r3 r4; do echo "hostname $n" | FRR_EXTRA="ripd ospfd eigrpd" frr $n; done
}

# bgp: a company with its own block, 203.0.113.0/24, and its own autonomous
# system, 64500, connected to two providers that also peer with each other.
# The providers are configured here; the company's router, edge, starts with
# nothing, and lesson 17 types its BGP configuration.
#
#            www 203.0.113.10
#                 |
#               edge (AS 64500)
#              /              \
#   192.0.2.0/30              192.0.2.4/30
#            /                  \
#   ispa (AS 64501) --------- ispb (AS 64502)
#        |         192.0.2.8/30      |
#   a1 198.51.100.10          b1 198.51.100.130
#   (198.51.100.0/25)         (198.51.100.128/25)
isp_bgp() {  # isp_bgp NODE ASN OWN-PREFIX CUSTOMER-ADDRESS PEER-ADDRESS PEER-ASN
  frr "$1" <<CONF
hostname $1
ip prefix-list CUSTOMER seq 5 permit 203.0.113.0/24
route-map FROM-CUSTOMER permit 10
 match ip address prefix-list CUSTOMER
route-map ANY permit 10
router bgp $2
 bgp router-id $4
 neighbor 192.0.2.$([ "$2" = 64501 ] && echo 1 || echo 5) remote-as 64500
 neighbor $5 remote-as $6
 address-family ipv4 unicast
  network $3
  neighbor 192.0.2.$([ "$2" = 64501 ] && echo 1 || echo 5) route-map FROM-CUSTOMER in
  neighbor 192.0.2.$([ "$2" = 64501 ] && echo 1 || echo 5) route-map ANY out
  neighbor $5 route-map ANY in
  neighbor $5 route-map ANY out
 exit-address-family
CONF
}
scenario_bgp() {
  node www; node a1; node b1
  node edge router; node ispa router; node ispb router
  link www eth0 edge eth0;  addr www eth0 203.0.113.10/24; addr edge eth0 203.0.113.1/24; gw www 203.0.113.1
  link edge eth1 ispa eth0; addr edge eth1 192.0.2.1/30; addr ispa eth0 192.0.2.2/30
  link edge eth2 ispb eth0; addr edge eth2 192.0.2.5/30; addr ispb eth0 192.0.2.6/30
  link ispa eth1 ispb eth1; addr ispa eth1 192.0.2.9/30; addr ispb eth1 192.0.2.10/30
  link a1 eth0 ispa eth2;   addr a1 eth0 198.51.100.10/25;  addr ispa eth2 198.51.100.1/25;   gw a1 198.51.100.1
  link b1 eth0 ispb eth2;   addr b1 eth0 198.51.100.130/25; addr ispb eth2 198.51.100.129/25; gw b1 198.51.100.129
  isp_bgp ispa 64501 198.51.100.0/25   192.0.2.2 192.0.2.10 64502
  isp_bgp ispb 64502 198.51.100.128/25 192.0.2.6 192.0.2.9  64501
  echo "hostname edge" | FRR_EXTRA=bgpd frr edge
}

# vlans: two switches joined by one cable (port p24 on each), with VLAN
# filtering switched on and no VLANs configured, so every port starts in the
# default VLAN 1. Lesson 19 puts each port in its VLAN. pc5 is the odd one:
# it will be put in VLAN 20 while its address says 10.20.10.0/24.
#
#   pc1 (10.20.10.21)  pc2 (10.20.20.22)       pc3 (10.20.10.23)  pc4 (10.20.20.24)
#           p1 \      / p2                          p1 \      / p2   p3 -- pc5 (10.20.10.25)
#               sw1 ---------- p24 ---- p24 ---------- sw2
vlans_build() {
  local n
  for n in pc1 pc2 pc3 pc4 pc5 sw1 sw2; do node $n; done
  link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2
  link pc3 eth0 sw2 p1; link pc4 eth0 sw2 p2; link pc5 eth0 sw2 p3
  link sw1 p24 sw2 p24
  addr pc1 eth0 10.20.10.21/24; addr pc3 eth0 10.20.10.23/24; addr pc5 eth0 10.20.10.25/24
  addr pc2 eth0 10.20.20.22/24; addr pc4 eth0 10.20.20.24/24
}
scenario_vlans() {
  vlans_build
  switch sw1 "p1 p2 p24" vlan_filtering 1
  switch sw2 "p1 p2 p3 p24" vlan_filtering 1
}

# stp: three switches cabled in a triangle, a PC on each, and spanning tree
# off. The cable from sw3 to sw1 is left unplugged (its sw3 end set down),
# because with spanning tree off a triangle is a loop the moment it closes;
# lesson 20 plugs it in on purpose.
#
#          pc1
#           | p10
#          sw1
#     p2  /    \  p3
#     p1 /      \ p1   (unplugged)
#      sw2 ---- sw3
#       | p3  p2 |
#      pc2      pc3   (both on p10)
scenario_stp() {
  local n
  for n in sw1 sw2 sw3 pc1 pc2 pc3; do node $n; done
  link sw1 p2 sw2 p1; link sw2 p3 sw3 p2; link sw3 p1 sw1 p3
  link pc1 eth0 sw1 p10; link pc2 eth0 sw2 p10; link pc3 eth0 sw3 p10
  ip -n sw3 link set p1 down
  switch sw1 "p2 p3 p10"; switch sw2 "p1 p3 p10"; switch sw3 "p1 p2 p10"
  addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr pc3 eth0 10.20.10.23/24
}

# lag: two switches joined by two cables (e1 and e2 on each end) that are not
# yet part of either switch. pc1 is on sw1; pc2, pc3 and pc4 on sw2. Lesson 21
# bundles the two cables with LACP.
#
#   pc1 -- sw1 ==(e1, e2)== sw2 -- pc2, pc3, pc4
scenario_lag() {
  local n
  for n in sw1 sw2 pc1 pc2 pc3 pc4; do node $n; done
  link sw1 e1 sw2 e1; link sw1 e2 sw2 e2
  link pc1 eth0 sw1 p1; link pc2 eth0 sw2 p1; link pc3 eth0 sw2 p2; link pc4 eth0 sw2 p3
  switch sw1 "p1"; switch sw2 "p1 p2 p3"
  addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24
  addr pc3 eth0 10.20.10.23/24; addr pc4 eth0 10.20.10.24/24
}

# intervlan: one switch with two VLANs already configured, as lesson 19 left
# them, and a router cabled to port p8, which is a trunk carrying both. The
# router has no address yet: lesson 22 gives it one per VLAN, and later moves
# the routing into the switch itself.
#
#   pc1 (VLAN 10, 10.20.10.21) --p1\
#   srv (VLAN 10, 10.20.10.10) --p3-- sw1 --p8 (trunk: 10, 20)-- r1
#   pc2 (VLAN 20, 10.20.20.22) --p2/
scenario_intervlan() {
  node pc1; node pc2; node srv; node sw1; node r1 router
  link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link srv eth0 sw1 p3; link r1 eth0 sw1 p8
  switch sw1 "p1 p2 p3 p8" vlan_filtering 1
  local p
  for p in p1 p3; do ip netns exec sw1 bridge vlan add dev $p vid 10 pvid untagged; ip netns exec sw1 bridge vlan del dev $p vid 1; done
  ip netns exec sw1 bridge vlan add dev p2 vid 20 pvid untagged; ip netns exec sw1 bridge vlan del dev p2 vid 1
  ip netns exec sw1 bridge vlan add dev p8 vid 10; ip netns exec sw1 bridge vlan add dev p8 vid 20
  addr pc1 eth0 10.20.10.21/24; addr srv eth0 10.20.10.10/24; addr pc2 eth0 10.20.20.22/24
  gw pc1 10.20.10.1; gw srv 10.20.10.1; gw pc2 10.20.20.1
  web srv 10.20.10.10
}

case "${1:-}" in
  up) up "${2:?which scenario? try: lab.sh list}" ;;
  down) down ;;
  exec) shift; exec_on "$@" ;;
  rogue) rogue_dhcp ;;
  list) declare -F | awk '$3 ~ /^scenario_/ {sub("scenario_", "", $3); print $3}' ;;
  *) sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 2 ;;
esac
