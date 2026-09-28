#!/usr/bin/env bash
# The network every transcript in this course was recorded on.
#
# IT IS ONE LINUX COMPUTER. Each machine below is a network namespace: its own
# interfaces, addresses, routes and firewall, its own hostname, and its own
# copy of the few directories a machine is told apart by (a home folder, a
# daemon's configuration, its logs). The cables are virtual Ethernet pairs
# plugged into bridges, one bridge per segment. They carry no delay, so every
# round trip in the lessons is one computer talking to itself.
#
# THE SHAPE IS THE COURSE'S SUBJECT: one firewall, fw, with five legs, and a
# segment behind each one that trusts the others differently.
#
#   internet  203.0.113.0/24   the outside: remote (a stranger), branch (the
#                              branch office's router, reached over a VPN)
#   dmz       192.0.2.0/24     what the internet may reach: www, dns
#   lan       192.168.10.0/24  the staff's computers: laptop, desk
#   servers   192.168.20.0/24  what only the company reaches: app, db
#   mgmt      192.168.99.0/24  where administration comes from: admin
#   branch    192.168.30.0/24  behind branch: branchpc
#
# sensor is plugged into the DMZ with no address at all, the way an intrusion
# detection sensor listens: it reads the segment and never speaks on it.
#
# NOTHING HERE REACHES THE REAL INTERNET, and nothing in it is anybody else's.
# The addresses and names are the ones reserved for documentation and testing
# (RFC 5737, RFC 1918, RFC 2606), which is why they are safe to print.
#
# fw ROUTES AND FILTERS NOTHING when the lab comes up. Every rule in the
# course is typed in a lesson, in front of the reader, because a firewall the
# reader did not watch being written teaches nothing about writing one.
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
internet fw       eth0 203.0.113.2/24
internet remote   eth0 203.0.113.50/24
internet branch   eth0 203.0.113.70/24
dmz      fw       eth1 192.0.2.1/24
dmz      www      eth0 192.0.2.80/24
dmz      dns      eth0 192.0.2.53/24
lan      fw       eth2 192.168.10.1/24
lan      laptop   eth0 192.168.10.20/24
lan      desk     eth0 192.168.10.21/24
servers  fw       eth3 192.168.20.1/24
servers  app      eth0 192.168.20.10/24
servers  db       eth0 192.168.20.30/24
mgmt     fw       eth4 192.168.99.1/24
mgmt     admin    eth0 192.168.99.10/24
dmz      sensor   eth0 none
branch   branch   eth1 192.168.30.1/24
branch   branchpc eth0 192.168.30.20/24
"
#            host      gateway
ROUTES="
remote   203.0.113.2
branch   203.0.113.2
www      192.0.2.1
dns      192.0.2.1
laptop   192.168.10.1
desk     192.168.10.1
app      192.168.20.1
db       192.168.20.1
admin    192.168.99.1
branchpc 192.168.30.1
"
HOSTS=$(echo "$LINKS" | awk 'NF{print $2}' | sort -u)
ROUTERS="fw branch"

need() {
  local missing=()
  for p in iproute2 nftables conntrack tcpdump openssl nginx libnginx-mod-http-modsecurity modsecurity-crs suricata jq wireguard-tools wireguard-go \
           dnsmasq bind9 bind9-dnsutils unbound netcat-openbsd curl iputils-ping iputils-arping socat openssh-server \
           softflowd nfdump aide hostapd wpasupplicant python3 python3-cryptography python3-cffi-backend ethtool; do
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
    # IPv6 is off in the lab (the kernel it was recorded on has none): every
    # rule in the course is written for IPv4, and lesson 5 says what that leaves out.
    [ -e /proc/sys/net/ipv6 ] && ip netns exec "$h" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    ip netns exec "$h" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    local peer="v$((n + 1))-$h"
    n=$((n + 1))
    ip link add "$peer" type veth peer name "lab-tmp$n"
    ip link set "lab-tmp$n" netns "$h"
    ip -n "$h" link set "lab-tmp$n" name "$ifc"
    if [ "$addr" = none ]; then
      ip -n "$h" link set "$ifc" address 52:54:00:00:00:99
    else
      ip -n "$h" link set "$ifc" address "$(mac "$addr")"
      ip -n "$h" addr add "$addr" dev "$ifc"
    fi
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
  # The branch's own network is reached through the tunnel of lesson 10, and
  # through nothing else: fw has no route to it until that lesson adds one.
  # A switch that floods every frame to every port, so a sensor plugged into a
  # segment sees what crosses it: the lab's stand-in for a mirror port.
  for seg in dmz lan; do ip -n wire link set "br-$seg" type bridge ageing_time 0; done
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="root home etc/nginx var/www var/log/nginx etc/ssh etc/ssl/private etc/suricata var/log/suricata var/lib/suricata etc/aide var/lib/aide etc/wireguard etc/dnsmasq.d var/log/lab srv etc/bind var/cache/bind etc/unbound var/lib/unbound run/wireguard"
overlay() {
  local h=$1 p
  for p in $OVERLAY; do
    [ -e "$LAB/$h/$p" ] && [ -e "/$p" ] && mount --bind "$LAB/$h/$p" "/$p"
  done
  return 0
}

# The machines run Ubuntu 24.04's own Python, 3.12, whatever python3 means on
# the computer hosting the lab: /lab/bin comes first on every PATH.
python_shim() {
  mkdir -p "$LAB/bin"
  ln -sf /usr/bin/python3.12 "$LAB/bin/python3"
}

exec_on() {  # exec_on HOST USER COMMAND
  local h=$1 u=$2 c=$3
  ip netns exec "$h" unshare --uts bash -c '
    '"$(declare -f overlay)"'; LAB='"$LAB"'; OVERLAY="'"$OVERLAY"'"
    hostname "$1"; overlay "$1"
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/lab/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/lab/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana" "$LAB/$h/var/log/lab" "$LAB/$h/srv" "$LAB/$h/root" "$LAB/$h/run/wireguard"
    chmod 700 "$LAB/$h/root"
    {
      printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h"
      # every machine knows the others by name, as an internal DNS would say
      echo "$LINKS" | awk 'NF && $2 != "fw" && $2 != "branch" && $4 != "none" {split($4,a,"/"); print a[1], $2}'
      printf '192.168.10.1 fw\n192.0.2.80 www.example.com\n203.0.113.70 branch\n'
    } > "/etc/netns/$h/hosts"
    printf 'nameserver 192.0.2.53\n' > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    cp -a /etc/skel/. "$LAB/$h/home/ana/"
    chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
  done
}

# ------------------------------------------------------------------ services
# www is the reverse proxy in the DMZ; app is the application behind it, on
# the servers segment; db stands in for a database with a listener on 5432
# that answers one line, because what the course examines is who may reach the
# port and never what is behind it.
build_services() {
  # the application: a directory of pages served by Python on app
  mkdir -p "$LAB/app/srv/app/admin"
  printf 'orders service: ok\n' > "$LAB/app/srv/app/index.html"
  printf 'admin console\n' > "$LAB/app/srv/app/admin/index.html"
  printf 'status: ok\n' > "$LAB/app/srv/app/health"
  # GET serves the directory; POST takes a form and says so, the way the
  # support form of any shop would
  cat > "$LAB/app/srv/app.py" <<'PY'
import http.server, functools
class App(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        self.rfile.read(n)
        body = b'received\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
handler = functools.partial(App, directory='/srv/app')
http.server.ThreadingHTTPServer(('192.168.20.10', 8080), handler).serve_forever()
PY

  # the reverse proxy on www
  mkdir -p "$LAB/www/etc/nginx" "$LAB/www/var/www" "$LAB/www/var/log/nginx"
  cp -a /etc/nginx/. "$LAB/www/etc/nginx/"
  rm -f "$LAB/www/etc/nginx/sites-enabled/"*
  cat > "$LAB/www/etc/nginx/sites-enabled/shop" <<'CONF'
server {
    listen 192.0.2.80:80;
    server_name www.example.com;
    location / {
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
CONF
  sed -i 's#^\(\s*\)access_log .*#\1access_log /var/log/nginx/access.log;#' "$LAB/www/etc/nginx/nginx.conf"
  sed -i 's/^user .*/user www-data;/' "$LAB/www/etc/nginx/nginx.conf"

  # the name server in the DMZ: answers for the company's names and nothing else
  mkdir -p "$LAB/dns/etc/dnsmasq.d"
  cat > "$LAB/dns/etc/dnsmasq.d/lab.conf" <<'CONF'
no-resolv
no-hosts
listen-address=192.0.2.53
bind-interfaces
host-record=www.example.com,192.0.2.80
host-record=dns.example.com,192.0.2.53
host-record=vpn.example.com,203.0.113.2
host-record=app.corp.example.com,192.168.20.10
host-record=db.corp.example.com,192.168.20.30
log-queries
log-facility=/var/log/lab/dnsmasq.log
CONF
}


# -------------------------------------------------------------------- DNSSEC
# Lesson 8's signed zone. dns keeps answering the company's names with dnsmasq
# on port 53; beside it, BIND serves the same zone SIGNED on port 5300, and
# laptop runs a validating resolver, Unbound, on its own loopback, which asks
# BIND and trusts the zone's key because it was told to. The keys are made
# fresh on every build, so key tags and signatures differ between runs.
build_dnssec() {
  local b="$LAB/dns/etc/bind" c="$LAB/dns/var/cache/bind"
  mkdir -p "$b" "$c"
  cp -a /etc/bind/. "$b/"
  cat > "$b/db.example.com" <<'Z'
$TTL 300
@        SOA  dns.example.com. hostmaster.example.com. 2026092801 3600 900 1209600 300
@        NS   dns.example.com.
dns      A    192.0.2.53
www      A    192.0.2.80
Z
  ( cd "$b" && dnssec-keygen -q -a ECDSAP256SHA256 -f KSK example.com >/dev/null && dnssec-keygen -q -a ECDSAP256SHA256 example.com >/dev/null
    for k in Kexample.com.*.key; do echo "\$INCLUDE $k" >> db.example.com; done
    dnssec-signzone -q -S -K . -o example.com -N keep -s 20260901000000 -e 20261231000000 -f db.example.com.signed db.example.com >/dev/null
    grep -h 'DNSKEY 257' Kexample.com.*.key | awk '{print $1, "DNSKEY", $4, $5, $6, $7 $8 $9 $10}' > "$LAB/ksk.txt" )
  cat > "$b/named.conf" <<'CONF'
options {
  directory "/var/cache/bind";
  listen-on port 5300 { 192.0.2.53; };
  listen-on-v6 { none; };
  recursion no;
  # nothing here may ask the real internet anything: no trust anchor
  # telemetry and no DNSSEC validation of its own, both of which make BIND
  # query the real root servers
  dnssec-validation no;
  trust-anchor-telemetry no;
  pid-file "/var/cache/bind/named.pid";
};
zone "example.com" { type primary; file "/etc/bind/db.example.com.signed"; };
CONF
  chown -R bind:bind "$b" "$c"
  local u="$LAB/laptop/etc/unbound"
  mkdir -p "$u" "$LAB/laptop/var/lib/unbound"
  grep 'DNSKEY 257' "$b"/Kexample.com.*.key | sed 's/^[^:]*://' > "$u/example.com.key"
  cat > "$u/unbound.conf" <<'CONF'
server:
  interface: 127.0.0.1
  port: 53
  do-not-query-localhost: no
  username: ""
  chroot: ""
  pidfile: "/var/lib/unbound/unbound.pid"
  use-syslog: no
  logfile: "/var/lib/unbound/unbound.log"
  verbosity: 1
  val-log-level: 2
  module-config: "validator iterator"
  trust-anchor-file: "/etc/unbound/example.com.key"
remote-control:
  control-enable: yes
  control-interface: 127.0.0.1
  control-use-cert: no
stub-zone:
  name: "example.com"
  stub-addr: 192.0.2.53@5300
CONF
}

# ------------------------------------------------------------------ probe
# probe HOST:PORT...  tries a TCP connection to each and says what happened,
# one line each: open (it answered), refused (a machine said nothing listens
# there), or blocked (nothing came back within a second: a firewall dropped
# it). The one tool in the lab that is not a standard command; it is nc -z
# with the result written in words.
build_probe() {
  cat > /usr/local/bin/probe <<'SH'
#!/bin/bash
for t in "$@"; do
  h=${t%:*}; p=${t##*:}
  out=$(nc -z -v -w1 "$h" "$p" 2>&1)
  case $out in
    *succeeded*) r=open ;;
    *refused*) r=refused ;;
    *) r=blocked ;;
  esac
  printf '%-22s %s\n' "$t" "$r"
done
SH
  chmod 755 /usr/local/bin/probe
}

# ------------------------------------------------------------ the baseline
# The company's policy as lesson 4 leaves it, written to fw as a file and NOT
# loaded: a lesson that needs it loads it in front of the reader, or says in
# its capture script that it was loaded before the lesson began.
build_baseline() {
  cat > "$LAB/fw/root/baseline.nft" <<'NFT'
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new accept comment "staff browse"
    iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 53 ct state new accept comment "staff resolve names"
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport { 80, 443 } ct state new accept comment "the world reaches the shop"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new accept comment "the world asks our names"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
    iifname "eth4" oifname { "eth1", "eth3" } tcp dport 22 ct state new accept comment "administration over SSH"
  }
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
  }
}
NFT
}

# ------------------------------------------------------------------------ TLS
# The company's own certificate authority: a root that signs an issuing CA
# that signs the servers. Every date is fixed, so every certificate printed in
# the course says the same thing on every run: openssl ca is the one tool here
# that takes explicit dates.
CA_START=20260901000000Z
ca_conf() {
  cat > "$LAB/ca/ca.cnf" <<CNF
[ca]
default_ca = ca
[ca]
dir = $LAB/ca
database = \$dir/index.txt
new_certs_dir = \$dir/newcerts
serial = \$dir/serial
default_md = sha256
policy = anything
unique_subject = no
copy_extensions = none
[anything]
organizationName = optional
commonName = supplied
[root]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
[issuing]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
[server]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = serverAuth
authorityKeyIdentifier = keyid
[client]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = clientAuth
authorityKeyIdentifier = keyid
CNF
}
# issue NAME EXTENSIONS SIGNER START END [SAN]  -> $LAB/ca/NAME.{key,crt}
# A name goes in through an extension file of its own, because the names are
# the one extension that differs between two servers.
issue() {
  local n=$1 ext=$2 signer=$3 start=$4 end=$5 san=${6:-}
  cd "$LAB/ca"
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "$(subj "$n")" -keyout "$n.key" -out "$n.csr" 2>/dev/null
  if [ "$signer" = self ]; then
    openssl ca -batch -config ca.cnf -selfsign -keyfile "$n.key" -extensions "$ext" -startdate "$start" -enddate "$end" -in "$n.csr" -out "$n.crt" -notext 2>/dev/null
  else
    if [ -n "$san" ]; then
      { sed -n "/^\[$ext\]/,/^\[/p" ca.cnf | sed '$d'; echo "subjectAltName = $san"; } > "$n.ext"
      openssl ca -batch -config ca.cnf -cert "$signer.crt" -keyfile "$signer.key" -extfile "$n.ext" -extensions "$ext" -startdate "$start" -enddate "$end" -in "$n.csr" -out "$n.crt" -notext 2>/dev/null
    else
      openssl ca -batch -config ca.cnf -cert "$signer.crt" -keyfile "$signer.key" -extensions "$ext" -startdate "$start" -enddate "$end" -in "$n.csr" -out "$n.crt" -notext 2>/dev/null
    fi
  fi
}
subj() {
  case $1 in
    root) echo "/O=Example Corp/CN=Example Corp Root CA" ;;
    issuing) echo "/O=Example Corp/CN=Example Corp Issuing CA" ;;
    *) echo "/CN=$1" ;;
  esac
}
build_tls() {
  mkdir -p "$LAB/ca/newcerts"; : > "$LAB/ca/index.txt"; echo 1000 > "$LAB/ca/serial"
  ca_conf
  issue root root self $CA_START 20360901000000Z
  issue issuing issuing root $CA_START 20310901000000Z
  issue www.example.com server issuing $CA_START 20261130000000Z "DNS:www.example.com,DNS:example.com"
  cat "$LAB/ca/www.example.com.crt" "$LAB/ca/issuing.crt" > "$LAB/ca/www.example.com.chain"
  cp "$LAB/ca/root.crt" /usr/local/share/ca-certificates/example-corp-root-ca.crt
  update-ca-certificates >/dev/null 2>&1
  mkdir -p "$LAB/www/etc/ssl/private"
  cp "$LAB/ca/www.example.com.chain" "$LAB/www/etc/ssl/private/www.crt"
  cp "$LAB/ca/www.example.com.key" "$LAB/www/etc/ssl/private/www.key"
  cat >> "$LAB/www/etc/nginx/sites-enabled/shop" <<'CONF'
server {
    listen 192.0.2.80:443 ssl;
    server_name www.example.com;
    ssl_certificate     /etc/ssl/private/www.crt;
    ssl_certificate_key /etc/ssl/private/www.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
CONF
}

# ------------------------------------------------------------------------ SSH
sshd_conf() {  # sshd_conf HOST ADDRESS PORT
  local s="$LAB/$1/etc/ssh"
  mkdir -p "$s"
  cp -a /etc/ssh/. "$s/"
  rm -f "$s"/ssh_host_*
  ssh-keygen -q -t ed25519 -N '' -C "root@$1" -f "$s/ssh_host_ed25519_key"
  cat > "$s/sshd_config" <<C
ListenAddress $2:$3
HostKey /etc/ssh/ssh_host_ed25519_key
PidFile /run/sshd-$1.pid
KbdInteractiveAuthentication no
PasswordAuthentication no
UsePAM yes
PrintMotd no
Subsystem sftp internal-sftp
C
}
build_ssh() {
  mkdir -p /run/sshd
  # remote runs SSH on 443, the port a firewall leaves open for HTTPS: what
  # lesson 2 shows a port number cannot tell apart.
  sshd_conf remote 203.0.113.50 443
  for h in app db; do sshd_conf "$h" "$(echo "$LINKS" | awk -v h=$h '$2==h{split($4,a,"/");print a[1]}')" 22; done
}

# --------------------------------------------------------------------- sensor
# Suricata's configuration for the two machines that run it: fw, reading its
# own LAN interface (lesson 2), and sensor, listening on the DMZ (lessons 14
# to 16). Only the rules a lesson writes are loaded: local.rules starts empty.
build_suricata() {
  for h in fw sensor; do
    local d="$LAB/$h/etc/suricata"
    mkdir -p "$d/rules" "$LAB/$h/var/log/suricata" "$LAB/$h/var/lib/suricata"
    cp -a /etc/suricata/. "$d/"
    sed -i 's#^default-rule-path: .*#default-rule-path: /etc/suricata/rules#' "$d/suricata.yaml"
    sed -i '/^rule-files:/{n;s#.*#  - local.rules#}' "$d/suricata.yaml"
    sed -i 's#^    HOME_NET: .*#    HOME_NET: "[192.168.0.0/16,192.0.2.0/24]"#' "$d/suricata.yaml"
    : > "$d/rules/local.rules"
    # two copies may run at once, so neither takes the one command socket
    sed -i '/^unix-command:/,/^[a-z]/{s/^  enabled: .*/  enabled: no/}' "$d/suricata.yaml"
  done
}

daemon() {  # daemon HOST COMMAND
  exec_on "$1" root "setsid $2 </dev/null >/dev/null 2>&1 &"
}

start() {
  exec_on app root "setsid python3 -u /srv/app.py </dev/null >>/var/log/lab/app.log 2>&1 &"
  daemon db "socat TCP-LISTEN:5432,bind=192.168.20.30,fork,reuseaddr SYSTEM:'echo db ready'"
  daemon www "nginx"
  for h in remote app db; do daemon "$h" "/usr/sbin/sshd -f /etc/ssh/sshd_config"; done
  daemon dns "named -u bind -c /etc/bind/named.conf"
  daemon laptop "unbound -d -c /etc/unbound/unbound.conf"
  daemon dns "dnsmasq --conf-dir=/etc/dnsmasq.d --pid-file=/var/log/lab/dnsmasq.pid --user=root"
  for _ in $(seq 50); do
    exec_on laptop ana 'curl -s -m 1 -o /dev/null http://www.example.com/' 2>/dev/null && break
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
  for h in $HOSTS printer ips guest sw newpc visitor admin2; do rm -rf "/etc/netns/$h"; done
  rm -f /usr/local/share/ca-certificates/example-corp-root-ca.crt
  update-ca-certificates --fresh >/dev/null 2>&1 || true
  rm -rf "$LAB"
}

up() {
  if ip netns list | grep -qw wire; then return 0; fi
  need
  mkdir -p "$LAB"
  # the real paths the overlay mounts over have to exist on the computer
  for p in $OVERLAY; do mkdir -p "/$p"; done
  build_net
  python_shim
  hostfiles
  build_services
  build_baseline
  build_probe
  build_dnssec
  build_tls
  build_ssh
  build_suricata
  start
}

# A device plugged into a segment of a running lab, with a MAC given by hand
# rather than derived from its address: lesson 7's printer, configured by
# mistake with an address somebody else already has.
plug() {  # plug HOST SEGMENT ADDRESS/PREFIX MAC
  local h=$1 seg=$2 addr=$3 m=$4 peer="p-$1"
  ip netns add "$h"
  ip -n "$h" link set lo up
  ip link add "$peer" type veth peer name lab-plug
  ip link set lab-plug netns "$h"
  ip -n "$h" link set lab-plug name eth0
  ip -n "$h" link set eth0 address "$m"
  ip -n "$h" addr add "$addr" dev eth0
  ip -n "$h" link set eth0 up
  ip link set "$peer" netns wire
  ip -n wire link set "$peer" master "br-$seg"
  ip -n wire link set "$peer" up
  mkdir -p "/etc/netns/$h" "$LAB/$h/root" "$LAB/$h/home/ana" "$LAB/$h/run/wireguard"
  printf '%s\n' "$h" > "/etc/netns/$h/hostname"
  cp /etc/netns/laptop/hosts /etc/netns/laptop/resolv.conf "/etc/netns/$h/"
  cp -a /etc/skel/. "$LAB/$h/home/ana/"; chown -R ana:ana "$LAB/$h/home/ana"
}

# Lessons 14 and 15's intrusion prevention: a machine called ips put INLINE on
# the DMZ's link to fw, a bump in the wire with two interfaces and no address.
# fw's DMZ cable is unplugged from the DMZ switch and plugged into ips:eth0;
# ips:eth1 goes to the switch. Nothing reaches the DMZ from fw, or leaves it
# towards fw, without crossing ips. Suricata bridges the two in its IPS mode
# (af-packet, copy-mode ips), so if Suricata stops, the link stops too.
inline() {
  local fwport
  fwport=$(ip -n wire -o link show master br-dmz | awk -F': ' '{print $2}' | grep -- '-fw@' | cut -d@ -f1)
  ip netns add ips
  ip -n ips link set lo up
  ip -n wire link set "$fwport" nomaster
  ip -n wire link set "$fwport" netns ips
  ip -n ips link set "$fwport" name eth0
  ip link add i-ips type veth peer name lab-ips
  ip link set lab-ips netns ips
  ip -n ips link set lab-ips name eth1
  ip link set i-ips netns wire
  ip -n wire link set i-ips master br-dmz
  ip -n wire link set i-ips up
  for i in eth0 eth1; do
    ip -n ips link set "$i" up
    ip netns exec ips ethtool -K "$i" gro off gso off tso off >/dev/null 2>&1 || true
  done
  # Virtual cables leave TCP checksums for hardware that is not there to fill
  # in; a packet Suricata copies from one side to the other would arrive with
  # an unfinished one and be dropped. The machines on both sides compute them.
  ip netns exec fw ethtool -K eth1 tx off >/dev/null 2>&1 || true
  for h in www dns; do ip netns exec "$h" ethtool -K eth0 tx off >/dev/null 2>&1 || true; done
  mkdir -p "/etc/netns/ips" "$LAB/ips/root" "$LAB/ips/home/ana" "$LAB/ips/var/log/suricata" "$LAB/ips/var/lib/suricata"
  printf 'ips\n' > /etc/netns/ips/hostname
  mkdir -p "$LAB/ips/etc"
  cp -a "$LAB/sensor/etc/suricata" "$LAB/ips/etc/"
  # the two interfaces Suricata joins, and one flow table across both: with
  # use-for-tracking on, Suricata 7 keeps a flow per interface, sees the
  # answer to a connection as a stranger, and drops it
  cat > "$LAB/ips/etc/suricata/inline.yaml" <<'Y'
%YAML 1.1
---
af-packet:
  - interface: eth0
    copy-mode: ips
    copy-iface: eth1
    cluster-id: 98
    cluster-type: cluster_flow
    defrag: no
  - interface: eth1
    copy-mode: ips
    copy-iface: eth0
    cluster-id: 97
    cluster-type: cluster_flow
    defrag: no
livedev:
  use-for-tracking: false
Y
}

# Lesson 22's access switch. sw is a switch in a namespace: a bridge joining
# its uplink, plugged into the staff LAN, to two access ports, p1 and p2, where
# newpc and visitor are plugged in. hostapd runs 802.1X on both ports as the
# authenticator, with its own EAP server and EAP-TLS: a client proves itself
# with a certificate from the company's CA.
#
# A real switch keeps an unauthenticated port closed in its hardware. Linux
# does not do that for a bridge port, so the lab does it the way it is written
# out in the lesson: a netdev chain on each port lets through nothing but
# 802.1X frames (EtherType 0x888e) until hostapd reports the port authorised,
# and hostapd_cli, on that event, adds the client's MAC to the set of
# authorised stations.
nac() {
  local ca="$LAB/ca" a b
  ip netns add sw; ip -n sw link set lo up
  ip -n sw link add br0 type bridge
  ip link add up1 type veth peer name v-swup
  ip link set up1 netns sw; ip -n sw link set up1 master br0
  ip link set v-swup netns wire; ip -n wire link set v-swup master br-lan; ip -n wire link set v-swup up
  for pair in "p1 newpc 192.168.10.30 52:54:00:a8:0a:1e" "p2 visitor 192.168.10.31 52:54:00:a8:0a:1f"; do
    set -- $pair
    ip netns add "$2"; ip -n "$2" link set lo up
    ip link add "$1" type veth peer name lab-nac
    ip link set "$1" netns sw; ip -n sw link set "$1" master br0; ip -n sw link set "$1" up
    ip link set lab-nac netns "$2"; ip -n "$2" link set lab-nac name eth0
    ip -n "$2" link set eth0 address "$4"
    ip -n "$2" addr add "$3/24" dev eth0; ip -n "$2" link set eth0 up
    ip -n "$2" route add default via 192.168.10.1
    mkdir -p "/etc/netns/$2" "$LAB/$2/root" "$LAB/$2/home/ana" "$LAB/$2/var/log/lab" "$LAB/$2/run/wireguard"
    printf '%s\n' "$2" > "/etc/netns/$2/hostname"
    cp /etc/netns/laptop/hosts /etc/netns/laptop/resolv.conf "/etc/netns/$2/"
    cp -a /etc/skel/. "$LAB/$2/home/ana/"; chown -R ana:ana "$LAB/$2/home/ana"
  done
  ip -n sw link set up1 up; ip -n sw link set br0 up
  mkdir -p /etc/netns/sw "$LAB/sw/root" "$LAB/sw/var/log/lab" "$LAB/sw/run/wireguard"
  printf 'sw\n' > /etc/netns/sw/hostname
  # the certificates: the authenticator's, and one for newpc; visitor gets a
  # certificate it signed itself, which is what an unmanaged device can offer
  ( cd "$ca"
    for n in "nac.corp.example.com server DNS:nac.corp.example.com" "newpc.corp.example.com client"; do
      set -- $n
      openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=$1" -keyout "$1.key" -out "$1.csr" 2>/dev/null
      { sed -n "/^\[$2\]/,/^\[/p" ca.cnf | sed '$d'; [ -n "${3:-}" ] && echo "subjectAltName = $3"; } > "$1.ext"
      openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile "$1.ext" -extensions "$2" \
        -startdate 20260928000000Z -enddate 20261228000000Z -in "$1.csr" -out "$1.crt" -notext 2>/dev/null
    done )
  cp "$ca/nac.corp.example.com.crt" "$LAB/sw/root/server.crt"; cp "$ca/nac.corp.example.com.key" "$LAB/sw/root/server.key"
  cat "$ca/issuing.crt" "$ca/root.crt" > "$LAB/sw/root/ca.crt"
  for h in newpc visitor; do cat "$ca/issuing.crt" "$ca/root.crt" > "$LAB/$h/root/ca.crt"; done
  cp "$ca/newpc.corp.example.com.crt" "$LAB/newpc/root/client.crt"; cp "$ca/newpc.corp.example.com.key" "$LAB/newpc/root/client.key"
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=visitor" \
    -keyout "$LAB/visitor/root/client.key" -out "$LAB/visitor/root/client.crt" 2>/dev/null
  for h in newpc visitor; do
    cat > "$LAB/$h/root/wpa.conf" <<C
ctrl_interface=/root/wpa-ctrl
ap_scan=0
network={
    key_mgmt=IEEE8021X
    eap=TLS
    identity="$h.corp.example.com"
    ca_cert="/root/ca.crt"
    client_cert="/root/client.crt"
    private_key="/root/client.key"
    eapol_flags=0
}
C
  done
  for port in p1 p2; do
    cat > "$LAB/sw/root/hostapd-$port.conf" <<C
interface=$port
driver=wired
logger_stdout=-1
logger_stdout_level=2
ieee8021x=1
eap_server=1
eap_user_file=/root/eap_user
ca_cert=/root/ca.crt
server_cert=/root/server.crt
private_key=/root/server.key
ctrl_interface=/root/hostapd-ctrl
C
  done
  printf '* TLS\n' > "$LAB/sw/root/eap_user"
  cat > "$LAB/sw/root/port-control.sh" <<'SH'
#!/bin/bash
# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC
case $2 in
  AP-STA-CONNECTED)    nft add element netdev ports authorised "{ $3 }" ;;
  AP-STA-DISCONNECTED) nft delete element netdev ports authorised "{ $3 }" ;;
esac
SH
  chmod +x "$LAB/sw/root/port-control.sh"
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  plug) shift; plug "$@" ;;
  inline) inline ;;
  nac) nac ;;
  *) echo "usage: lab.sh up|down|reset|exec HOST USER COMMAND|plug HOST SEGMENT ADDRESS MAC" >&2; exit 2 ;;
esac
