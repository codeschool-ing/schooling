#!/usr/bin/env bash
# The small company every transcript in this course was recorded at.
#
# IT IS ONE LINUX COMPUTER. Each machine below is a network namespace: its own
# interfaces, addresses, routes and firewall, its own hostname, and its own
# copy of the few directories a machine is told apart by (a home folder, /srv,
# /root, its SSH configuration, its sudo rules, its logs). The cables are
# virtual Ethernet pairs plugged into bridges, one bridge per segment. The
# shape is the one networks-security builds in full; this is the part of it a
# fundamentals course needs.
#
#   internet  203.0.113.0/24   outside: a machine on the internet, used for
#                              the tests that come from outside
#   dmz       192.0.2.0/24     www: the shop and the staff portal
#   office    192.168.10.0/24  laptop: the staff's computer
#   servers   192.168.20.0/24  db: the orders database and its backups
#
# fw joins the four and, when the lab comes up, FORWARDS EVERYTHING AND FILTERS
# NOTHING. Lesson 5 writes its rules in front of the reader. Nothing in the lab
# translates addresses either: outside's route to the company runs straight
# through fw, which a real network would hide behind NAT. NAT is not a
# security control, and the lesson that draws the network says so.
#
# NOTHING HERE REACHES THE REAL INTERNET, and nothing in it is anybody else's.
# The addresses and names are the ones reserved for documentation and testing
# (RFC 5737, RFC 1918, RFC 2606), which is why they are safe to print. Every
# test in the course is run by the company's own IT person, ana, against the
# company's own machines.
#
# THE PEOPLE. ana (1001) runs IT; bruno (1002) runs finance and is in the
# group hr (1100); shop (990) is the account the portal runs as. lab.sh
# creates them when they are missing, with those numbers, because id prints
# them and the lessons quote what it printed.
#
# THE SERVICES, started by `up`:
#   www  portal.py on 192.0.2.80:80, as shop. GET / says the shop is open;
#        /handbook is the staff handbook; /payslips/NAME is one person's
#        payslip. Its policy for /handbook reads /srv/portal/mode, which says
#        `perimeter` (anything from the office network may read it) or
#        `zerotrust` (anybody may, after signing in, from anywhere).
#        It sends no Date and no Server header, so a transcript of its replies
#        is the same on every run.
#   db   a listener on 192.168.20.30:5432 that stands in for the database:
#        what the course examines is who may reach the port, never what
#        answers on it.
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
internet fw      eth0 203.0.113.2/24
internet outside eth0 203.0.113.50/24
dmz      fw      eth1 192.0.2.1/24
dmz      www     eth0 192.0.2.80/24
office   fw      eth2 192.168.10.1/24
office   laptop  eth0 192.168.10.20/24
servers  fw      eth3 192.168.20.1/24
servers  db      eth0 192.168.20.30/24
"
#            host      gateway
ROUTES="
outside  203.0.113.2
www      192.0.2.1
laptop   192.168.10.1
db       192.168.20.1
"
HOSTS=$(echo "$LINKS" | awk 'NF{print $2}' | sort -u)

need() {
  local missing=()
  for p in iproute2 nftables netcat-openbsd curl openssh-server oathtool python3 sudo; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
}

people() {
  getent group hr >/dev/null || groupadd -g 1100 hr
  id ana >/dev/null 2>&1 || useradd -m -u 1001 -s /bin/bash ana
  id bruno >/dev/null 2>&1 || useradd -m -u 1002 -G hr -s /bin/bash bruno
  id shop >/dev/null 2>&1 || useradd -r -u 990 -d /nonexistent -s /usr/sbin/nologin shop
  [ "$(id -u ana)/$(id -u bruno)/$(id -u shop)/$(getent group hr | cut -d: -f3)" = 1001/1002/990/1100 ] || {
    echo "ana, bruno, shop and hr exist with other numbers; this needs a throwaway machine" >&2; exit 1; }
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
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    n=$((n + 1))
    local peer="sf$n-$h"
    ip link add "$peer" type veth peer name "sf-tmp$n"
    ip link set "sf-tmp$n" netns "$h"
    ip -n "$h" link set "sf-tmp$n" name "$ifc"
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
  ip netns exec fw sysctl -qw net.ipv4.ip_forward=1
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="root home srv backup etc/ssh etc/sudoers.d var/log/lab"
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
  mkdir -p /backup /srv /var/log/lab
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home" "$LAB/$h/var/log/lab" "$LAB/$h/srv" "$LAB/$h/root" \
             "$LAB/$h/backup" "$LAB/$h/etc/sudoers.d"
    chmod 700 "$LAB/$h/root"
    chmod 750 "$LAB/$h/etc/sudoers.d"
    {
      printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h"
      printf '192.0.2.80 www www.example.com\n192.168.10.20 laptop\n192.168.20.30 db db.corp.example.com\n203.0.113.50 outside\n'
    } > "/etc/netns/$h/hosts"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    for u in ana bruno; do
      mkdir -p "$LAB/$h/home/$u"
      cp -a /etc/skel/. "$LAB/$h/home/$u/"
      chown -R "$u:$u" "$LAB/$h/home/$u"; chmod 750 "$LAB/$h/home/$u"
    done
  done
}

# ------------------------------------------------------------------- www
build_www() {
  local s="$LAB/www/srv"
  mkdir -p "$s/portal" "$s/hr"
  printf 'perimeter\n' > "$s/portal/mode"
  # Passwords are kept as PBKDF2 hashes with a salt each, the way lesson 9
  # says a server should keep them. The salts are fixed so the file is the same
  # on every build; the passwords are the lab's and protect nothing.
  python3 - "$s/portal/users" <<'PY'
import hashlib, sys
rows = [('ana', 'staff', 'lab-ana-pass'), ('bruno', 'staff,hr', 'lab-bruno-pass')]
with open(sys.argv[1], 'w') as f:
    for name, groups, pw in rows:
        salt = hashlib.sha256(name.encode()).hexdigest()[:16]
        h = hashlib.pbkdf2_hmac('sha256', pw.encode(), salt.encode(), 200000).hex()
        f.write(f'{name}:{groups}:{salt}:{h}\n')
PY
  cat > "$s/portal/portal.py" <<'PY'
# The staff portal of shop.example.com. Three pages and one policy each.
import base64, hashlib, hmac, http.server, ipaddress, sys

OFFICE = ipaddress.ip_network('192.168.10.0/24')

def users():
    out = {}
    for line in open('/srv/portal/users'):
        name, groups, salt, h = line.strip().split(':')
        out[name] = (set(groups.split(',')), salt, h)
    return out

def mode():
    return open('/srv/portal/mode').read().strip()

class Portal(http.server.BaseHTTPRequestHandler):
    def send_response(self, code, message=None):
        # No Date and no Server header: the transcripts stay the same on every run.
        self.log_request(code)
        self.send_response_only(code, message)

    def log_message(self, fmt, *args):
        with open('/var/log/lab/portal.log', 'a') as f:
            f.write('%s %s %s\n' % (self.client_address[0], getattr(self, 'user', '-'), fmt % args))

    def reply(self, code, body, extra=()):
        data = body.encode()
        self.send_response(code)
        for k, v in extra:
            self.send_header(k, v)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def who(self):
        """The signed-in user, or None. Authentication: is this person who they say?"""
        auth = self.headers.get('Authorization', '')
        if not auth.startswith('Basic '):
            return None
        try:
            name, pw = base64.b64decode(auth[6:]).decode().split(':', 1)
        except Exception:
            return None
        u = users().get(name)
        if not u:
            return None
        groups, salt, h = u
        mine = hashlib.pbkdf2_hmac('sha256', pw.encode(), salt.encode(), 200000).hex()
        if not hmac.compare_digest(mine, h):
            return None
        self.user = name
        return name, groups

    def ask_to_sign_in(self):
        self.reply(401, 'sign in first\n', [('WWW-Authenticate', 'Basic realm="staff"')])

    def do_GET(self):
        path = self.path
        if path == '/':
            return self.reply(200, 'shop.example.com: open\n')
        if path == '/handbook':
            if mode() == 'perimeter':
                if ipaddress.ip_address(self.client_address[0]) in OFFICE:
                    return self.reply(200, 'staff handbook: page 1 of 40\n')
                return self.reply(403, 'only from the office network\n')
            if self.who() is None:
                return self.ask_to_sign_in()
            return self.reply(200, 'staff handbook: page 1 of 40\n')
        if path.startswith('/payslips/'):
            owner = path[len('/payslips/'):]
            me = self.who()
            if me is None:
                return self.ask_to_sign_in()
            name, groups = me
            # Authorisation: may THIS person see THAT payslip?
            if name != owner and 'hr' not in groups:
                return self.reply(403, 'not yours to read\n')
            if owner not in users():
                return self.reply(404, 'no such payslip\n')
            return self.reply(200, 'payslip for %s, September 2026\n' % owner)
        return self.reply(404, 'not found\n')

http.server.ThreadingHTTPServer(('192.0.2.80', 80), Portal).serve_forever()
PY
  # The finance spreadsheet the portal must never be able to read.
  printf 'name,monthly\nana,7800\nbruno,8200\n' > "$s/hr/salaries.csv"
  chown -R root:root "$s/portal"; chmod 644 "$s/portal/"*; chmod 640 "$s/portal/users"; chgrp shop "$s/portal/users"
  chown bruno:hr "$s/hr" "$s/hr/salaries.csv"; chmod 750 "$s/hr"; chmod 640 "$s/hr/salaries.csv"
  touch "$LAB/www/var/log/lab/portal.log"; chown shop "$LAB/www/var/log/lab/portal.log"
  # sudo on www: ana may restart the portal and read its log, and nothing else.
  cat > "$LAB/www/etc/sudoers.d/ana" <<'S'
ana ALL=(root) NOPASSWD: /usr/local/sbin/portal-restart, /usr/bin/tail /var/log/lab/portal.log
S
  chmod 440 "$LAB/www/etc/sudoers.d/ana"
  # sshd's configuration on www, as the package ships it: lesson 16 checks it.
  mkdir -p "$LAB/www/etc/ssh/sshd_config.d"
  cp /usr/share/openssh/sshd_config "$LAB/www/etc/ssh/sshd_config"
  ssh-keygen -q -t ed25519 -N '' -C '' -f "$LAB/www/etc/ssh/ssh_host_ed25519_key"
  mkdir -p /run/sshd
}

# -------------------------------------------------------------------- db
build_db() {
  local s="$LAB/db/srv/shop"
  mkdir -p "$s/data" "$s/invoices"
  printf 'order,customer,total_cents,date\n1001,c-0042,8990,2026-10-01\n1002,c-0107,4590,2026-10-02\n1003,c-0042,12900,2026-10-03\n' > "$s/data/orders.csv"
  printf 'customer,email\nc-0042,leitora@example.com\nc-0107,comprador@example.net\n' > "$s/data/customers.csv"
  for d in 01 02 03; do printf 'invoice for order 100%s\n' "${d#0}" > "$s/invoices/2026-10-$d.txt"; done
  find "$s" -exec touch -h -d '2026-10-04 18:00:00 -0300' {} +
  mkdir -p "$LAB/db/backup"
  # The backup job as it was written in March, before invoices/ existed.
  cat > "$LAB/db/root/backup.sh" <<'SH'
#!/bin/bash
# Nightly backup of the shop's data, written in March.
set -e
day=$1
tar --sort=name --mtime='2026-10-04 18:00:00 -0300' --owner=0 --group=0 --numeric-owner \
    -cf - -C /srv/shop data | gzip -n > /backup/shop-$day.tar.gz
SH
  chmod 755 "$LAB/db/root/backup.sh"
  cat > "$LAB/db/srv/listener.py" <<'PY'
import socketserver
class H(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.sendall(b'orders database\n')
socketserver.ThreadingTCPServer.allow_reuse_address = True
socketserver.ThreadingTCPServer(('192.168.20.30', 5432), H).serve_forever()
PY
}

# ---------------------------------------------------------------- tools
# probe HOST:PORT...  tries a TCP connection to each and says what happened,
# one line each: open (it answered), refused (a machine said nothing listens
# there), or blocked (nothing came back within a second: a firewall dropped
# it). It is nc -z with the result written in words.
build_tools() {
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
  # Restarting the portal is a script so that sudo can name it exactly.
  cat > /usr/local/sbin/portal-restart <<SH
#!/bin/bash
[ -f /srv/portal/portal.pid ] && kill "\$(cat /srv/portal/portal.pid)" 2>/dev/null
sleep 0.3
setsid setpriv --reuid=990 --regid=990 --clear-groups --inh-caps=+net_bind_service --ambient-caps=+net_bind_service python3 /srv/portal/portal.py </dev/null >/dev/null 2>&1 &
echo \$! > /srv/portal/portal.pid
sleep 0.7
echo "portal restarted"
SH
  chmod 755 /usr/local/sbin/portal-restart
}

start_services() {
  exec_on www root '/usr/local/sbin/portal-restart >/dev/null'
  exec_on db root 'setsid python3 /srv/listener.py </dev/null >/dev/null 2>&1 & echo $! > /srv/listener.pid'
  sleep 0.5
}

stop_services() {
  local f
  for f in "$LAB/www/srv/portal/portal.pid" "$LAB/db/srv/listener.pid"; do
    [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null || true
  done
}

down() {
  stop_services
  for h in $HOSTS wire; do ip netns del "$h" 2>/dev/null || true; done
  rm -rf "$LAB" /etc/netns/{outside,fw,www,laptop,db}
}

up() {
  need; people
  if ip netns list | grep -qw wire; then return 0; fi
  build_net; hostfiles; build_www; build_db; build_tools; start_services
}

case ${1:-} in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  *) echo "usage: lab.sh up|down|reset|exec HOST USER 'command'" >&2; exit 2 ;;
esac
