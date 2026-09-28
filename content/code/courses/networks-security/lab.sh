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
  for p in iproute2 nftables conntrack tcpdump openssl nginx suricata jq wireguard-tools wireguard-go \
           dnsmasq bind9-dnsutils netcat-openbsd curl iputils-ping arping socat openssh-server \
           softflowd nfdump aide hostapd wpasupplicant python3; do
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
OVERLAY="home etc/nginx var/www var/log/nginx etc/ssh etc/ssl/private etc/suricata var/log/suricata var/lib/suricata etc/aide var/lib/aide etc/wireguard etc/dnsmasq.d var/log/lab srv"
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
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana" "$LAB/$h/var/log/lab" "$LAB/$h/srv"
    {
      printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h"
      # every machine knows the others by name, as an internal DNS would say
      echo "$LINKS" | awk 'NF && $2 != "fw" && $2 != "branch" {split($4,a,"/"); print a[1], $2}'
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
CONF
}

daemon() {  # daemon HOST COMMAND
  exec_on "$1" root "setsid $2 </dev/null >/dev/null 2>&1 &"
}

start() {
  daemon app "python3 -m http.server --bind 192.168.20.10 --directory /srv/app 8080"
  daemon db "socat TCP-LISTEN:5432,bind=192.168.20.30,fork,reuseaddr SYSTEM:'echo db ready'"
  daemon www "nginx"
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
  for h in $HOSTS; do rm -rf "/etc/netns/$h"; done
  rm -rf "$LAB"
}

up() {
  if ip netns list | grep -qw wire; then return 0; fi
  need
  mkdir -p "$LAB"
  # the real paths the overlay mounts over have to exist on the computer
  for p in $OVERLAY; do mkdir -p "/$p"; done
  build_net
  hostfiles
  build_services
  start
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  *) echo "usage: lab.sh up|down|reset|exec HOST USER COMMAND" >&2; exit 2 ;;
esac
