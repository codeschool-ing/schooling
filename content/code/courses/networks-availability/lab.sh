#!/usr/bin/env bash
# The network every transcript in this course was recorded on.
#
# IT IS ONE LINUX COMPUTER. Each machine below is a network namespace with its
# own interfaces, addresses, routes and firewall, its own hostname and its own
# /run, so two daemons of the same kind on two "machines" never share a pid
# file or a control socket. The cables are virtual Ethernet pairs plugged into
# bridges that live in a namespace of their own, called wire; capturing on a
# port of one of those bridges is the lab's mirror port.
#
# WHAT THE KERNEL COULD NOT DO, AND WHAT STANDS IN FOR IT. The kernel this was
# recorded on was built without GRE, IP-in-IP, WireGuard, ESP and netem. So:
#   - GRE and IP-in-IP are tunnel.py, below: forty lines of Python that move
#     packets between a TUN device and a raw socket. What they put on the wire
#     is standard GRE (protocol 47) and IP-in-IP (protocol 4), and tcpdump
#     decodes it as such. On an ordinary Linux the same tunnel is one
#     `ip link add ... type gre` line, which the lessons show and mark as not
#     run here.
#   - WireGuard is wireguard-go, the userspace implementation by the same
#     author. `wg` talks to it exactly as it talks to the kernel module.
#   - IPsec is strongSwan with its kernel-libipsec plugin: IKEv2 and ESP done
#     in userspace, over a TUN device. It speaks tunnel mode only, which is
#     why transport mode is described and not captured.
#   - There is no added delay on any link. Every round trip is one computer
#     talking to itself, a fraction of a millisecond, and the prose says so
#     wherever a time is read. Loss, where a lesson needs it, is an nftables
#     rule that drops a share of packets at random (numgen), and it is shown.
#
# NOTHING HERE REACHES THE REAL INTERNET. The addresses are private ranges for
# the offices and the ones reserved for documentation (RFC 5737) for
# everything public: 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24. The
# names are example.com and example.net (RFC 2606), served by the lab's own
# DNS server.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           tear it down and build it again
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'
#   sudo bash lab.sh kill HOST PATTERN [SIGNAL]
#   sudo bash lab.sh span SEGMENT HOST     mirror HOST's port to mon
#
# Recorded on Ubuntu 24.04 (see the packages in need() below).
set -euo pipefail

LAB=/lab
TZ_LAB=America/Sao_Paulo
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

#        segment  host     iface address/prefix
LINKS="
hq       hq       eth0 192.168.10.1/24
hq       hq2      eth0 192.168.10.3/24
hq       files    eth0 192.168.10.10/24
hq       laptop   eth0 192.168.10.20/24
hqwan    hq       eth1 203.0.113.2/24
hqwan    hq2      eth1 203.0.113.3/24
hqwan    isp      eth0 203.0.113.1/24
branch   branch   eth0 192.168.20.1/24
branch   till     eth0 192.168.20.30/24
net      branch   eth1 198.51.100.2/24
net      homegw   eth1 198.51.100.77/24
net      isp      eth1 198.51.100.1/24
home     homegw   eth0 192.168.1.1/24
home     remote   eth0 192.168.1.50/24
dc       isp      eth2 192.0.2.1/24
dc       ns       eth0 192.0.2.53/24
dc       lb1      eth0 192.0.2.11/24
dc       lb2      eth0 192.0.2.12/24
dc       web1     eth0 192.0.2.21/24
dc       web2     eth0 192.0.2.22/24
dc       web3     eth0 192.0.2.23/24
"
#            host      gateway
ROUTES="
hq       203.0.113.1
hq2      203.0.113.1
files    192.168.10.1
laptop   192.168.10.1
branch   198.51.100.1
till     192.168.20.1
homegw   198.51.100.1
remote   192.168.1.1
ns       192.0.2.1
lb1      192.0.2.1
lb2      192.0.2.1
web1     192.0.2.1
web2     192.0.2.1
web3     192.0.2.1
"
# mon is the analyst's machine: one interface, no address, plugged into no
# segment. span() copies a port's traffic to it, which is what a switch's
# mirror port (SPAN) does.
HOSTS=$( (echo "$LINKS" | awk 'NF{print $2}'; echo mon) | sort -u)
ROUTERS="hq hq2 branch homegw isp"

need() {
  local missing=()
  for p in iproute2 nftables bind9 bind9-dnsutils nginx openssl tcpdump tshark traceroute mtr-tiny \
           iperf3 netcat-openbsd curl iputils-ping ethtool wireguard-tools wireguard-go openvpn \
           strongswan-swanctl strongswan-charon libcharon-extra-plugins keepalived haproxy python3 sudo; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  id ana >/dev/null 2>&1 || { echo "create the user first: useradd -m -s /bin/bash ana" >&2; exit 1; }
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
    # IPv6 is off: every address in the course is IPv4, and a v6 link-local
    # chattering in every capture would be noise nobody asked about.
    [ -e /proc/sys/net/ipv6/conf/all ] && ip netns exec "$h" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    ip netns exec "$h" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    local peer="$seg-$h"
    n=$((n + 1))
    ip link add "$peer" type veth peer name "lab-tmp$n"
    ip link set "lab-tmp$n" netns "$h"
    ip -n "$h" link set "lab-tmp$n" name "$ifc"
    ip -n "$h" link set "$ifc" address "$(mac "$addr")"
    ip -n "$h" addr add "$addr" dev "$ifc"
    ip -n "$h" link set "$ifc" up
    # A real cable carries frames of at most 1514 bytes. A virtual one lets the
    # kernel pass 64 KB lumps and split them later, which would make every
    # capture, shaper and policer in the course count the wrong thing.
    ip netns exec "$h" ethtool -K "$ifc" tso off gso off gro off >/dev/null 2>&1
    ip link set "$peer" netns wire
    ip -n wire link set "$peer" master "br-$seg"
    ip -n wire link set "$peer" up
  done
  ip link add mon-port type veth peer name lab-mon
  ip link set lab-mon netns mon
  ip -n mon link set lab-mon name eth0
  ip -n mon link set eth0 address 52:54:00:00:00:99 up
  ip link set mon-port netns wire
  ip -n wire link set mon-port up
  echo "$ROUTES" | while read -r h gw; do
    [ -n "$h" ] || continue
    ip -n "$h" route add default via "$gw"
  done
  for r in $ROUTERS; do ip netns exec "$r" sysctl -qw net.ipv4.ip_forward=1; done
  # The ISP knows the public addresses and nothing private: 192.168.x.x never
  # crosses it, which is the whole reason the offices need a tunnel.
  # Each office has one public address, and every machine inside borrows it.
  for r in hq hq2 branch homegw; do
    ip netns exec "$r" nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" ip daddr != { 192.168.0.0/16, 10.0.0.0/8 } masquerade
  }
}
NFT
  done
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="home run etc/swanctl etc/wireguard etc/openvpn etc/keepalived etc/haproxy"
overlay() {
  local h=$1 p
  for p in $OVERLAY; do
    [ -e "$LAB/$h/$p" ] && [ -e "/$p" ] && mount --bind "$LAB/$h/$p" "/$p"
  done
  return 0
}

exec_on() {  # exec_on HOST USER COMMAND
  local h=$1 u=$2 c=$3
  ip netns exec "$h" unshare --uts bash -c '
    '"$(declare -f overlay)"'; LAB='"$LAB"'; OVERLAY="'"$OVERLAY"'"
    hostname "$1"; overlay "$1"
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

hostfiles() {
  mkdir -p /etc/swanctl /etc/wireguard /etc/openvpn /etc/keepalived /etc/haproxy
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana" "$LAB/$h/run" \
             "$LAB/$h/etc/swanctl" "$LAB/$h/etc/wireguard" "$LAB/$h/etc/openvpn" \
             "$LAB/$h/etc/keepalived" "$LAB/$h/etc/haproxy"
    chmod 755 "$LAB/$h/run"; chmod 700 "$LAB/$h/etc/wireguard"
    printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h" > "/etc/netns/$h/hosts"
    printf 'nameserver 192.0.2.53\n' > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    cp -a /etc/skel/. "$LAB/$h/home/ana/"
    chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
  done
}

# ------------------------------------------------------------------------ DNS
build_dns() {
  local d="$LAB/ns/bind"
  mkdir -p "$d/cache"
  cat > "$d/named.conf" <<'CONF'
options {
  directory "/lab/ns/bind/cache";
  listen-on { 192.0.2.53; };
  listen-on-v6 { none; };
  recursion yes;
  allow-query { any; };
  allow-recursion { any; };
  dnssec-validation no;
  pid-file "/run/named.pid";
};
// No real internet behind this server: an empty root makes every other name
// an immediate NXDOMAIN rather than a wait for root servers nobody can reach.
zone "." { type primary; file "/lab/ns/bind/db.root"; };
zone "example.com" { type primary; file "/lab/ns/bind/db.example.com"; };
zone "example.net" { type primary; file "/lab/ns/bind/db.example.net"; };
CONF
  cat > "$d/db.root" <<'Z'
$TTL 86400
.            SOA  ns.example.com. hostmaster.example.com. 2026092801 1800 900 604800 86400
.            NS   ns.example.com.
ns.example.com. A 192.0.2.53
Z
  cat > "$d/db.example.com" <<'Z'
$TTL 300
@            SOA  ns.example.com. hostmaster.example.com. 2026092801 3600 900 1209600 300
@            NS   ns.example.com.
ns           A    192.0.2.53
www          A    192.0.2.80
lb1          A    192.0.2.11
lb2          A    192.0.2.12
web1         A    192.0.2.21
web2         A    192.0.2.22
web3         A    192.0.2.23
vpn          A    203.0.113.2
branch-vpn   A    198.51.100.2
files.hq     A    192.168.10.10
Z
  cat > "$d/db.example.net" <<'Z'
$TTL 300
@            SOA  ns.example.com. hostmaster.example.com. 2026092801 3600 900 1209600 300
@            NS   ns.example.com.
old          A    192.0.2.24
Z
  chown -R bind:bind "$d"
}

# ------------------------------------------------------------------------ TLS
# One certificate authority for the lab, and the certificates lesson 13 needs:
# a good one, one that expired, one for the wrong name, and one signed by an
# authority nobody trusts. Dates are fixed, so the expired one stays expired.
build_tls() {
  local t="$LAB/tls"; mkdir -p "$t"; cd "$t"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/O=Example Lab/CN=Example Lab Root CA" \
    -keyout ca.key -out ca.crt 2>/dev/null
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/O=Nobody/CN=Nobody Root CA" \
    -keyout rogue.key -out rogue.crt 2>/dev/null
  cert() {  # cert NAME CN CA START END — openssl ca, because it takes fixed dates
    openssl req -newkey rsa:2048 -nodes -subj "/CN=$2" -keyout "$1.key" -out "$1.csr" 2>/dev/null
    rm -rf db; mkdir db; : > db/index; echo 01 > db/serial
    cat > ca.cnf <<C
[ca]
default_ca = lab
[lab]
database = db/index
serial = db/serial
new_certs_dir = db
default_md = sha256
policy = any
copy_extensions = none
unique_subject = no
x509_extensions = ext
[any]
commonName = supplied
[ext]
subjectAltName = DNS:$2
extendedKeyUsage = serverAuth,clientAuth
keyUsage = digitalSignature,keyEncipherment
basicConstraints = CA:FALSE
C
    openssl ca -batch -config ca.cnf -cert "$3.crt" -keyfile "$3.key" -startdate "$4" -enddate "$5" \
      -in "$1.csr" -out "$1.crt" -notext 2>/dev/null
    rm -rf db ca.cnf "$1.csr"
  }
  cert www     www.example.com  ca    20260901000000Z 20270901000000Z
  cert expired www.example.com  ca    20250101000000Z 20260101000000Z
  cert other   shop.example.net ca    20260901000000Z 20270901000000Z
  cert rogue-www www.example.com rogue 20260901000000Z 20270901000000Z
  # OpenVPN's server and one client, from the same authority.
  cert vpn-server vpn.example.com ca 20260901000000Z 20270901000000Z
  cert vpn-ana    ana             ca 20260901000000Z 20270901000000Z
  cd - >/dev/null
  mkdir -p /usr/local/share/ca-certificates
  cp "$t/ca.crt" /usr/local/share/ca-certificates/example-lab-root-ca.crt
  update-ca-certificates >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------------ web
build_web() {
  for h in web1 web2 web3 files; do
    local r="$LAB/$h/www"; mkdir -p "$r/html" "$r/logs"
    printf 'served by %s\n' "$h" > "$r/html/index.html"
    head -c 20000000 /dev/zero > "$r/html/big.bin"
    head -c 3000 /dev/zero | tr '\0' 'x' > "$r/html/slow.txt"
    cat > "$r/nginx.conf" <<C
worker_processes 1;
pid /run/nginx.pid;
error_log $r/logs/error.log;
events { worker_connections 256; }
http {
  access_log $r/logs/access.log;
  server_tokens off;
  types { text/html html; text/plain txt; application/octet-stream bin; }
  server {
    listen 80;
    root $r/html;
    # slow.txt is 3000 bytes sent at 1000 a second, so a request for it
    # stays open about three seconds: what lesson 19 needs to make
    # least-connections disagree with round robin.
    location = /slow.txt { limit_rate 1000; }
  }
}
C
  done
  # www on the load balancers' address speaks TLS in lesson 13; the variants
  # are chosen by port so one server can show every way a handshake fails.
  local r="$LAB/web1/www"
  cat > "$LAB/web1/www/tls.conf" <<C
worker_processes 1;
pid /run/nginx-tls.pid;
error_log $r/logs/tls-error.log;
events { worker_connections 64; }
http {
  access_log $r/logs/tls-access.log;
  server_tokens off;
  server { listen 443 ssl; ssl_certificate $LAB/tls/www.crt;       ssl_certificate_key $LAB/tls/www.key;       return 200 "ok\n"; }
  server { listen 8443 ssl; ssl_certificate $LAB/tls/expired.crt;  ssl_certificate_key $LAB/tls/expired.key;  return 200 "ok\n"; }
  server { listen 9443 ssl; ssl_certificate $LAB/tls/other.crt;    ssl_certificate_key $LAB/tls/other.key;    return 200 "ok\n"; }
  server { listen 10443 ssl; ssl_certificate $LAB/tls/rogue-www.crt; ssl_certificate_key $LAB/tls/rogue-www.key; return 200 "ok\n"; }
}
C
}

# --------------------------------------------------------------------- tunnel
# GRE and IP-in-IP in userspace, because this kernel has neither (see the top).
build_tunnel() {
  install -m 755 /dev/stdin /usr/local/bin/tunnel.py <<'PY'
#!/usr/bin/env python3
"""A point-to-point tunnel: packets read from a TUN device leave inside an
outer IPv4 header, and packets arriving inside one are written back to it.

    tunnel.py gre|ipip NAME LOCAL REMOTE [KEY]
"""
import fcntl, os, select, socket, struct, sys

mode, name, local, remote = sys.argv[1:5]
key = int(sys.argv[5]) if len(sys.argv) > 5 else None

TUNSETIFF, IFF_TUN, IFF_NO_PI = 0x400454ca, 0x0001, 0x1000
tun = os.open("/dev/net/tun", os.O_RDWR)
fcntl.ioctl(tun, TUNSETIFF, struct.pack("16sH", name.encode(), IFF_TUN | IFF_NO_PI))

proto = 47 if mode == "gre" else 4        # the outer header's protocol field
wire = socket.socket(socket.AF_INET, socket.SOCK_RAW, proto)
wire.bind((local, 0))

def wrap(packet):
    if mode == "ipip":
        return packet                     # nothing between the two IP headers
    flags = 0x2000 if key is not None else 0     # K bit: a key follows
    head = struct.pack("!HH", flags, 0x0800)     # 0x0800: the payload is IPv4
    if key is not None:
        head += struct.pack("!I", key)
    return head + packet

def unwrap(outer):
    inner = outer[(outer[0] & 0x0F) * 4:]  # skip the outer IP header
    if mode == "ipip":
        return inner
    flags, ptype = struct.unpack("!HH", inner[:4])
    if ptype != 0x0800:
        return None
    if flags & 0x2000:
        if struct.unpack("!I", inner[4:8])[0] != key:
            return None                   # another tunnel's key: not ours
        return inner[8:]
    return None if key is not None else inner[4:]

while True:
    ready, _, _ = select.select([tun, wire], [], [])
    try:
        if tun in ready:
            wire.sendto(wrap(os.read(tun, 65535)), (remote, 0))
        if wire in ready:
            outer, (src, _) = wire.recvfrom(65535)
            packet = unwrap(outer) if src == remote else None
            if packet:
                os.write(tun, packet)
    except OSError:
        pass    # an ICMP error came back from the far end: this packet is
                # lost, as it would be in the kernel's own tunnel
PY
}

# ---------------------------------------------------------------------- IPsec
# strongSwan does IKE in userspace everywhere; here it does ESP there too,
# through kernel-libipsec, and sends it as raw protocol 50 when no NAT is in
# the way. These two files, the lab's root certificate in the system's store
# and dumpcap's capabilities (below) are the changes made outside /lab.
build_ipsec() {
  cat > /etc/strongswan.d/charon/kernel-libipsec.conf <<'C'
kernel-libipsec {
    load = yes
    raw_esp = yes
}
C
  # swanctl otherwise lists every plugin it was built to try and did not find.
  cat > /etc/strongswan.d/swanctl-quiet.conf <<'C'
swanctl {
  load = pem pkcs1 pkcs8 x509 revocation constraints pubkey openssl random
}
C
  for h in $HOSTS; do
    mkdir -p "$LAB/$h/etc/swanctl"/{conf.d,x509,x509ca,x509aa,x509ac,x509crl,x509ocsp,private,rsa,ecdsa,bliss,pkcs8,pkcs12,pubkey}
  done
}

# -------------------------------------------------------------------- capture
# Wireshark's own advice: capture as a member of the wireshark group, not as
# root. dumpcap, the one program that touches the interface, gets the two
# capabilities it needs; tshark and Wireshark run as the person. This is what
# `dpkg-reconfigure wireshark-common` does when asked to allow non-superusers.
build_capture() {
  groupadd -f -r wireshark
  chgrp wireshark /usr/bin/dumpcap
  chmod 750 /usr/bin/dumpcap
  setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
  usermod -aG wireshark ana
}

# --------------------------------------------------------------------- start
daemon() {  # daemon HOST COMMAND
  exec_on "$1" root "setsid $2 </dev/null >/dev/null 2>&1 &"
}
start() {
  daemon ns "named -u bind -c $LAB/ns/bind/named.conf"
  for h in web1 web2 web3 files; do daemon "$h" "nginx -c $LAB/$h/www/nginx.conf"; done
  daemon web1 "nginx -c $LAB/web1/www/tls.conf"
  for h in web1 web2 web3 files; do daemon "$h" "iperf3 -s -D"; done
  for _ in $(seq 50); do
    exec_on laptop ana 'dig +short +time=1 +tries=1 www.example.com' 2>/dev/null | grep -q . && break
    sleep 0.2
  done
}

down() {
  for h in $(ip netns list | awk '{print $1}'); do
    ip netns pids "$h" 2>/dev/null | xargs -r kill 2>/dev/null || true
  done
  sleep 0.5
  for h in $(ip netns list | awk '{print $1}'); do
    ip netns pids "$h" 2>/dev/null | xargs -r kill -9 2>/dev/null || true
    ip netns del "$h"
  done
  for h in $HOSTS; do rm -rf "/etc/netns/$h"; done
  rm -f /usr/local/share/ca-certificates/example-lab-root-ca.crt
  update-ca-certificates --fresh >/dev/null 2>&1 || true
  rm -rf "$LAB"
}

up() {
  if ip netns list | grep -qw wire; then return 0; fi
  need
  mkdir -p "$LAB"
  build_net
  hostfiles
  build_dns
  build_tls
  build_web
  build_tunnel
  build_ipsec
  build_capture
  start
}

# A mirror port: everything that enters or leaves HOST's port on SEGMENT is
# also sent out of mon's. Both directions, because a port that mirrored only
# what it received would show every question and none of the answers.
span() {  # span SEGMENT HOST
  local port="$1-$2"
  ip netns exec wire tc qdisc add dev "$port" ingress
  ip netns exec wire tc filter add dev "$port" parent ffff: protocol all u32 match u32 0 0 \
    action mirred egress mirror dev mon-port
  ip netns exec wire tc qdisc add dev "$port" handle 1: root htb
  ip netns exec wire tc filter add dev "$port" parent 1: protocol all u32 match u32 0 0 \
    action mirred egress mirror dev mon-port
}

# Every machine shares one process table, so `pkill` on one of them would
# reach into all the others. This kills only what runs on HOST.
kill_on() {  # kill_on HOST PATTERN [SIGNAL]
  local p
  for p in $(ip netns pids "$1"); do
    tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -qE "$2" && kill "-${3:-TERM}" "$p" 2>/dev/null
  done
  return 0
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  kill) shift; kill_on "$@" ;;
  span) shift; span "$@" ;;
  *) echo "usage: lab.sh up|down|reset|exec HOST USER COMMAND|kill HOST PATTERN [SIGNAL]|span SEGMENT HOST" >&2; exit 2 ;;
esac
