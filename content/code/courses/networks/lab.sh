#!/usr/bin/env bash
# The network every transcript in this course was recorded on.
#
# IT IS ONE LINUX COMPUTER. Each machine below is a network namespace: its own
# interfaces, addresses, routes and firewall, its own hostname, and its own
# copy of the few directories a machine is told apart by (a home folder, a
# daemon's configuration). The cables are virtual Ethernet pairs plugged into
# bridges. They carry no delay: the kernel this was recorded on has no netem,
# so every round trip in the lessons is one computer talking to itself, a
# fraction of a millisecond, and the prose says so wherever a time is read.
#
# NOTHING HERE REACHES THE REAL INTERNET. The lab has its own DNS root, its own
# top-level domains and its own certificate authorities, so every answer in the
# lessons is one these servers gave. The addresses and names are the ones
# reserved for documentation and testing (RFC 5737, RFC 2606, RFC 6761), which
# is why they are safe to print: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24,
# example.com, example.net and .test.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           tear it down and build it again
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'
#
# Recorded on Ubuntu 24.04 (see the packages in need() below).
set -euo pipefail

LAB=/lab
TZ_LAB=America/Sao_Paulo

#        segment  host     iface address/prefix
LINKS="
office   laptop   eth0 192.168.10.20/24
office   server   eth0 192.168.10.10/24
office   router   eth0 192.168.10.1/24
wan      router   eth1 203.0.113.2/24
wan      isp      eth0 203.0.113.1/24
backbone isp      eth1 198.51.100.1/24
backbone resolver eth0 198.51.100.53/24
backbone core     eth0 198.51.100.254/24
hosting  core     eth1 192.0.2.1/24
hosting  rootns   eth0 192.0.2.10/24
hosting  tldns    eth0 192.0.2.20/24
hosting  ns1      eth0 192.0.2.53/24
hosting  www      eth0 192.0.2.80/24
"
#            host      gateway
ROUTES="
laptop   192.168.10.1
server   192.168.10.1
router   203.0.113.1
resolver 198.51.100.1
core     198.51.100.1
rootns   192.0.2.1
tldns    192.0.2.1
ns1      192.0.2.1
www      192.0.2.1
"
HOSTS=$(echo "$LINKS" | awk 'NF{print $2}' | sort -u)
ROUTERS="router isp core"

need() {
  local missing=()
  for p in iproute2 bind9 bind9-dnsutils unbound nginx openssl tcpdump traceroute mtr-tiny \
           netcat-openbsd curl openssh-server nftables; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
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
    # IPv6 is off in the lab: the machine it was recorded on has no IPv6 at all.
    [ -e /proc/sys/net/ipv6 ] && ip netns exec "$h" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    # ping sends ICMP without privileges, as it does on the machine itself
    ip netns exec "$h" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    local peer="${seg:0:1}-$h"
    n=$((n + 1))
    ip link add "$peer" type veth peer name "lab-tmp$n"
    ip link set "lab-tmp$n" netns "$h"
    ip -n "$h" link set "lab-tmp$n" name "$ifc"
    ip -n "$h" link set "$ifc" address "$(mac "$addr")"
    ip -n "$h" addr add "$addr" dev "$ifc"
    ip -n "$h" link set "$ifc" up
    ip link set "$peer" netns wire
    ip -n wire link set "$peer" master "br-$seg"
    ip -n wire link set "$peer" up
  done
  echo "$ROUTES" | while read -r h gw; do
    [ -n "$h" ] || continue
    ip -n "$h" route add default via "$gw"
  done
  for r in $ROUTERS; do ip netns exec "$r" sysctl -qw net.ipv4.ip_forward=1; done
  ip -n isp route add 192.0.2.0/24 via 198.51.100.254
  ip -n core route add 203.0.113.0/24 via 198.51.100.1
  # The office has one public address, and every machine inside borrows it.
  ip netns exec router nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="home etc/bind var/cache/bind run/named etc/unbound etc/nginx var/www var/log/nginx etc/ssh etc/ssl/private"
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
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana"
    printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h" > "/etc/netns/$h/hosts"
    printf 'nameserver 198.51.100.53\n' > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    cp -a /etc/skel/. "$LAB/$h/home/ana/"
    chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
  done
  # The resolver asks the root, not itself.
  printf 'nameserver 127.0.0.1\n' > /etc/netns/resolver/resolv.conf
}

# ------------------------------------------------------------------------ DNS
SERIAL=2026092501
zone() {  # zone HOST NAME  (body on stdin)
  local d="$LAB/$1/etc/bind"
  mkdir -p "$d"; cat > "$d/db.${2%.}"
  printf 'zone "%s" { type primary; file "/etc/bind/db.%s"; };\n' "$2" "${2%.}" >> "$d/zones.conf"
}
named_conf() {  # named_conf HOST ADDRESS
  local d="$LAB/$1/etc/bind"
  mkdir -p "$d" "$LAB/$1/var/cache/bind" "$LAB/$1/run/named"
  cat > "$d/named.conf" <<CONF
options {
  directory "/var/cache/bind";
  listen-on { $2; };
  listen-on-v6 { none; };
  recursion no;
  allow-query { any; };
  dnssec-validation no;
  pid-file "/run/named/named.pid";
};
include "/etc/bind/zones.conf";
CONF
  : > "$d/zones.conf"
  chown -R bind:bind "$LAB/$1/var/cache/bind" "$LAB/$1/run/named"
}
build_dns() {
  named_conf rootns 192.0.2.10
  zone rootns . <<Z
\$TTL 86400
.                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
.                     NS    a.root-servers.test.
com.         172800   NS    a.gtld-servers.test.
net.         172800   NS    a.gtld-servers.test.
test.        172800   NS    a.root-servers.test.
arpa.        172800   NS    a.root-servers.test.
a.root-servers.test.  A     192.0.2.10
a.gtld-servers.test.  A     192.0.2.20
Z
  zone rootns test. <<Z
\$TTL 86400
@                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.root-servers.test.
a.root-servers        A     192.0.2.10
a.gtld-servers        A     192.0.2.20
Z
  zone rootns arpa. <<Z
\$TTL 86400
@                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.root-servers.test.
2.0.192.in-addr       NS    ns1.example.com.
113.0.203.in-addr     NS    ns1.example.com.
100.51.198.in-addr    NS    ns1.example.com.
Z
  named_conf tldns 192.0.2.20
  for tld in com net; do
    zone tldns "$tld." <<Z
\$TTL 86400
@                     SOA   a.gtld-servers.test. hostmaster.gtld-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.gtld-servers.test.
example      172800   NS    ns1.example.com.
Z
  done
  printf 'ns1.example.com. 172800 A 192.0.2.53\n' >> "$LAB/tldns/etc/bind/db.com"

  named_conf ns1 192.0.2.53
  zone ns1 example.com. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
@            A      192.0.2.80
@            MX     10 mail.example.com.
@            TXT    "v=spf1 mx -all"
ns1          A      192.0.2.53
www    300   A      192.0.2.80
www    300   AAAA   2001:db8:10::80
shop         CNAME  www.example.com.
mail         A      192.0.2.25
office       A      203.0.113.2
_dmarc       TXT    "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"
Z
  zone ns1 example.net. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.net. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
@            MX     10 mail.example.net.
@            TXT    "v=spf1 mx -all"
mail         A      192.0.2.26
Z
  zone ns1 2.0.192.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    core.example.net.
10           PTR    a.root-servers.test.
20           PTR    a.gtld-servers.test.
25           PTR    mail.example.com.
26           PTR    mail.example.net.
53           PTR    ns1.example.com.
80           PTR    www.example.com.
Z
  zone ns1 113.0.203.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    gw.isp.example.net.
2            PTR    office.example.com.
Z
  zone ns1 100.51.198.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    bb1.isp.example.net.
53           PTR    resolver.isp.example.net.
254          PTR    core.example.net.
Z
  for h in rootns tldns ns1; do chown -R root:bind "$LAB/$h/etc/bind"; done

  # The ISP's resolver: recursive, for its customers, starting from the root.
  local u="$LAB/resolver/etc/unbound"
  mkdir -p "$u"
  cat > "$u/root.hints" <<'H'
.                        3600000  NS  a.root-servers.test.
a.root-servers.test.     3600000  A   192.0.2.10
H
  cat > "$u/unbound.conf" <<'C'
server:
  interface: 198.51.100.53
  interface: 127.0.0.1
  access-control: 0.0.0.0/0 allow
  do-ip6: no
  root-hints: "/etc/unbound/root.hints"
  module-config: "iterator"
  chroot: ""
  username: "unbound"
  pidfile: "/run/unbound-resolver.pid"
  do-not-query-localhost: no
  qname-minimisation: no
  # Unbound answers these itself by default, because on the real internet
  # nobody should be serving them. In the lab they are the whole internet.
  local-zone: "test." nodefault
  local-zone: "2.0.192.in-addr.arpa." nodefault
  local-zone: "100.51.198.in-addr.arpa." nodefault
  local-zone: "113.0.203.in-addr.arpa." nodefault
  val-log-level: 0
  verbosity: 0
remote-control:
  control-enable: yes
  control-interface: 127.0.0.1
  control-use-cert: no
C
}

# ------------------------------------------------------------------ the web
build_tls() {
  local ca=$LAB/ca
  mkdir -p "$ca" && cd "$ca"
  # A root that signs an intermediate that signs the servers: the shape of
  # every public certificate, drawn at the size of a lab.
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 3650 \
    -subj "/O=Example Trust Services/CN=Example Root CA" -keyout root.key -out root.crt \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -subj "/O=Example Trust Services/CN=Example Issuing CA 1" -keyout issuing.key -out issuing.csr 2>/dev/null
  openssl x509 -req -in issuing.csr -CA root.crt -CAkey root.key -CAcreateserial -days 1825 -out issuing.crt \
    -extfile <(printf 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n') 2>/dev/null
  cp root.crt /usr/local/share/ca-certificates/example-root-ca.crt
  update-ca-certificates >/dev/null 2>&1
}
cert() {  # cert NAME DAYS SAN... -> $LAB/ca/NAME.{key,crt,chain}
  local n=$1 days=$2; shift 2
  local san; san=$(printf 'DNS:%s,' "$@"); san=${san%,}
  cd "$LAB/ca"
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=$1" -keyout "$n.key" -out "$n.csr" 2>/dev/null
  openssl x509 -req -in "$n.csr" -CA issuing.crt -CAkey issuing.key -CAcreateserial -days "$days" -out "$n.crt" \
    -extfile <(printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=critical,digitalSignature\nbasicConstraints=critical,CA:FALSE\n' "$san") 2>/dev/null
  cat "$n.crt" issuing.crt > "$n.chain"
}
build_web() {
  cert www.example.com 90 www.example.com example.com shop.example.com
  local n="$LAB/www/etc/nginx"
  mkdir -p "$n" "$LAB/www/var/www/example" "$LAB/www/var/log/nginx" "$LAB/www/etc/ssl/private"
  cp -a /etc/nginx/. "$n/"
  rm -f "$n/sites-enabled/"*
  cp "$LAB/ca/www.example.com.chain" "$LAB/www/etc/ssl/private/example.com.crt"
  cp "$LAB/ca/www.example.com.key" "$LAB/www/etc/ssl/private/example.com.key"
  sed -i 's#^pid .*#pid /run/nginx-www.pid;#; s#^worker_processes .*#worker_processes 1;#' "$n/nginx.conf"
  cat > "$n/sites-enabled/example.com" <<'SITE'
server {
    listen 80;
    server_name example.com www.example.com shop.example.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name example.com www.example.com shop.example.com;
    ssl_certificate     /etc/ssl/private/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    root /var/www/example;
    location / { try_files $uri $uri/ =404; }
}
SITE
  cat > "$LAB/www/var/www/example/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Example Ltd</title></head>
<body><h1>Example Ltd</h1><p>Accounting for small offices.</p></body>
</html>
HTML
  chown -R www-data:www-data "$LAB/www/var/log/nginx"
}

# ------------------------------------------------------------------------ SSH
sshd_conf() {  # sshd_conf HOST ADDRESS
  local s="$LAB/$1/etc/ssh"
  mkdir -p "$s"
  cp -a /etc/ssh/. "$s/"
  rm -f "$s"/ssh_host_*
  ssh-keygen -q -t ed25519 -N '' -C "root@$1" -f "$s/ssh_host_ed25519_key"
  cat > "$s/sshd_config" <<C
ListenAddress $2
HostKey /etc/ssh/ssh_host_ed25519_key
PidFile /run/sshd-$1.pid
KbdInteractiveAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp internal-sftp
C
}
build_ssh() {
  sshd_conf server 192.168.10.10
  sshd_conf www 192.0.2.80
  echo 'ana:office-2026' | chpasswd
}

# --------------------------------------------------------------------- start
daemon() {  # daemon HOST COMMAND
  exec_on "$1" root "$2 </dev/null >/dev/null 2>&1 &"
}
start() {
  for h in rootns tldns ns1; do daemon "$h" "named -u bind -c /etc/bind/named.conf"; done
  daemon resolver "unbound -c /etc/unbound/unbound.conf"
  daemon www "nginx"
  mkdir -p /run/sshd
  daemon server "/usr/sbin/sshd -f /etc/ssh/sshd_config"
  daemon www "/usr/sbin/sshd -f /etc/ssh/sshd_config"
  # Wait until the resolver can answer, so the first lesson line is not a timeout.
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
  rm -f /usr/local/share/ca-certificates/example-root-ca.crt
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
  build_ssh
  start
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  *) echo "usage: lab.sh up|down|reset|exec HOST USER COMMAND" >&2; exit 2 ;;
esac
