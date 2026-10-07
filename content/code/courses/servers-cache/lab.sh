#!/usr/bin/env bash
# The machine every transcript in the servers-cache course was recorded on.
#
# IT IS ONE UBUNTU 24.04 SERVER, called `web`, with one user, ana. Lesson 1
# tells the student to build theirs as a virtual machine (Multipass, or any
# hypervisor) and to install everything from Ubuntu's own archive with apt.
# This script builds the same server as a systemd-nspawn container, because
# the computer the course was recorded on could not run a hypervisor: the
# same release, the same packages at the same versions, booted by its own
# systemd, so `systemctl`, `journalctl` and the services behave as they do in
# a virtual machine. It has a network of its own with only loopback in it,
# so nothing it serves is reachable from anywhere else, and every name it uses
# is under .example (RFC 2606), answered by its own /etc/hosts.
#
# WHAT IS IN IT
#   from Ubuntu's archive, installed with apt exactly as lesson 1 says:
#     nginx, apache2, caddy, redis-server, memcached, libmemcached-tools,
#     varnish, apache2-utils (ab), certbot, python3-certbot-nginx, pebble,
#     python3-redis, python3-pymemcache
#   written for the course, and printed in full below:
#     /opt/shop/shop.py     the bookshop's catalogue API, Ipê Livros: Python's
#                           standard library and SQLite, nothing else
#     shop@.service         one unit, two instances: shop@1 on 127.0.0.1:8001
#                           and shop@2 on 127.0.0.1:8002
#     /var/www/ipe          the shop's static front: HTML, CSS, JS, a logo
#     ~/work/catalogue.py   the same database, as a Python module, for the
#                           cache code of lessons 8 to 11
#
# WHAT IS STAGED, AND WHY
#   - THE DATABASE IS SLOW ON PURPOSE. Every query the shop makes sleeps for
#     SHOP_QUERY_MS (120 ms) before it answers, because a twelve-row SQLite
#     file answers in microseconds and a cache in front of it would have
#     nothing to save. The number stands in for a real database under load;
#     the lessons say so wherever a time is read.
#   - Every file of the static site and every row of the database carries a
#     fixed date (2026-09-01), so Last-Modified and nginx's ETag are the same
#     on every run. The Date header is not: it is the clock.
#   - ana may use sudo without a password, which a real server would not
#     allow. It keeps the transcripts free of password prompts.
#   - Every service apt enables is DISABLED after installing, and each
#     lesson's `stage` starts the ones that lesson uses. Ubuntu starts every
#     server it installs, and three web servers all wanting port 80 is the
#     first thing lesson 1 shows; a lab that left that race to the boot order
#     would print a different winner on different runs.
#   - THE COMPUTER HAD NO IPv6, so a socket on [::] cannot be opened at all.
#     The one line that asks for one, `listen [::]:80 default_server;` in
#     nginx's packaged default site, is deleted. On a virtual machine of your
#     own it stays, and costs nothing.
#   - Pebble, Let's Encrypt's ACME server for testing, stands in for Let's
#     Encrypt in lesson 3: a real CA will only issue for a name it can reach
#     from the internet, and this machine has no such name. Pebble speaks the
#     same protocol, certbot talks to it unchanged, and its root CA is new on
#     every start, so fingerprints and serial numbers differ on every run.
#
#   sudo bash lab.sh install        ON YOUR OWN SERVER: apt-get install the
#                                   packages and write the course's files
#   sudo bash lab.sh build          the recording machine: debootstrap, then
#                                   `install` inside it (once)
#   sudo bash lab.sh reset [N]      a fresh copy of the server, booted, with
#                                   lesson N's services started
#   sudo bash lab.sh as 'cmd'       run a command as ana, in /home/ana, in a login shell
#   sudo bash lab.sh root 'cmd'     the same as root
#   sudo bash lab.sh down
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

BASE=/var/lib/machines/web-base
LIVE=/var/lib/machines/web
PIDFILE=/run/servers-cache-lab.pid
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1 TZ=America/Sao_Paulo

PACKAGES="nginx apache2 caddy redis-server redis-tools memcached libmemcached-tools
varnish apache2-utils certbot python3-certbot-nginx pebble python3-redis
python3-pymemcache"

nspawn() { systemd-nspawn -q --register=no --keep-unit --timezone=off "$@"; }

leader() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 1
  pgrep -P "$p" -x systemd | head -1
}

in_vm() { local l; l=$(leader) || { echo "lab is not running" >&2; exit 1; }
  nsenter -t "$l" -a env -i TERM=dumb LANG=C.UTF-8 TZ=America/Sao_Paulo \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }

write_files() { # $1 = root of the machine's filesystem, $2 = the work directory under it
  local R=$1 W=$2
  mkdir -p "$R/opt/shop" "$R/var/lib/shop" "$R/var/www/ipe/css" "$R/var/www/ipe/js" \
           "$R/var/www/ipe/img" "$R/etc/shop"

  cat > "$R/opt/shop/shop.py" <<'LABFILE'
#!/usr/bin/env python3
"""Ipê Livros, the bookshop's catalogue API. Written for the servers-cache course.

GET  /api/books           every book, id, title and price
GET  /api/books/<id>      one book; answers with an ETag and honours If-None-Match
PUT  /api/books/<id>      {"price_cents": N} changes a price
GET  /api/stats           how many database queries this instance has made
POST /api/stats/reset     sets that count back to zero
GET  /api/slow?s=N        answers after N seconds (at most 30)
GET  /api/echo            what this instance was told: the peer's address and
                          the headers a proxy adds
GET  /healthz             "ok"

Every answer says which instance gave it in X-Served-By, and every database
query sleeps SHOP_QUERY_MS milliseconds first: the stand-in for a busy database.
"""
import hashlib, json, os, sqlite3, threading, time
from email.utils import formatdate
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs

NAME = os.environ.get("SHOP_NAME", "shop1")
PORT = int(os.environ.get("SHOP_PORT", "8001"))
DB = os.environ.get("SHOP_DB", "/var/lib/shop/catalogue.db")
QUERY_MS = int(os.environ.get("SHOP_QUERY_MS", "120"))
CACHE_CONTROL = os.environ.get("SHOP_CACHE_CONTROL", "")

queries = 0
lock = threading.Lock()


def query(sql, args=()):
    global queries
    time.sleep(QUERY_MS / 1000)
    with lock:
        queries += 1
    with sqlite3.connect(DB) as db:
        db.row_factory = sqlite3.Row
        return [dict(r) for r in db.execute(sql, args)]


class Shop(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def version_string(self):
        return "ipe-shop/1.0"

    def log_message(self, fmt, *args):  # one line per request, to the journal
        print(f"{NAME} {self.command} {self.path} {args[1] if len(args) > 1 else ''}", flush=True)

    def send(self, code, body=b"", headers=()):
        self.send_response(code)
        self.send_header("X-Served-By", NAME)
        for k, v in headers:
            self.send_header(k, v)
        if code != 304:
            self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if code != 304 and self.command != "HEAD":
            self.wfile.write(body)

    def json(self, code, value, headers=()):
        body = (json.dumps(value, ensure_ascii=False) + "\n").encode()
        self.send(code, body, [("Content-Type", "application/json")] + list(headers))

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        url = urlsplit(self.path)
        parts = url.path.strip("/").split("/")
        if url.path == "/healthz":
            return self.send(200, b"ok\n", [("Content-Type", "text/plain")])
        if url.path == "/api/stats":
            return self.json(200, {"server": NAME, "db_queries": queries})
        if url.path == "/api/echo":
            h = self.headers
            return self.json(200, {"server": NAME, "peer": self.client_address[0],
                                   "host": h.get("Host"), "x_real_ip": h.get("X-Real-IP"),
                                   "x_forwarded_for": h.get("X-Forwarded-For"),
                                   "x_forwarded_proto": h.get("X-Forwarded-Proto")})
        if url.path == "/api/slow":
            s = min(float(parse_qs(url.query).get("s", ["1"])[0]), 30)
            time.sleep(s)
            return self.json(200, {"server": NAME, "slept": s})
        if url.path == "/api/books":
            rows = query("SELECT id, title, price_cents FROM books ORDER BY id")
            return self.json(200, rows, self.caching())
        if len(parts) == 3 and parts[:2] == ["api", "books"]:
            rows = query("SELECT * FROM books WHERE id = ?", (parts[2],))
            if not rows:
                return self.json(404, {"error": "no such book"})
            book = rows[0]
            body = (json.dumps(book, ensure_ascii=False) + "\n").encode()
            etag = '"' + hashlib.sha256(body).hexdigest()[:16] + '"'
            modified = formatdate(book["updated_at"], usegmt=True)
            headers = [("ETag", etag), ("Last-Modified", modified)] + self.caching()
            if etag in [t.strip() for t in self.headers.get("If-None-Match", "").split(",")]:
                return self.send(304, b"", headers)
            return self.send(200, body, [("Content-Type", "application/json")] + headers)
        return self.json(404, {"error": "not found"})

    def do_PUT(self):
        parts = urlsplit(self.path).path.strip("/").split("/")
        if len(parts) != 3 or parts[:2] != ["api", "books"]:
            return self.json(404, {"error": "not found"})
        n = int(self.headers.get("Content-Length", "0"))
        price = int(json.loads(self.rfile.read(n))["price_cents"])
        with sqlite3.connect(DB) as db:
            db.execute("UPDATE books SET price_cents = ?, updated_at = ? WHERE id = ?",
                       (price, int(time.time()), parts[2]))
        rows = query("SELECT * FROM books WHERE id = ?", (parts[2],))
        return self.json(200, rows[0])

    def do_POST(self):
        global queries
        if urlsplit(self.path).path == "/api/stats/reset":
            with lock:
                queries = 0
            return self.json(200, {"server": NAME, "db_queries": 0})
        return self.json(404, {"error": "not found"})

    def do_DELETE(self):
        return self.json(405, {"error": "method not allowed"})

    do_PATCH = do_DELETE

    def caching(self):
        return [("Cache-Control", CACHE_CONTROL)] if CACHE_CONTROL else []


if __name__ == "__main__":
    ThreadingHTTPServer.daemon_threads = True
    print(f"{NAME} listening on 127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Shop).serve_forever()
LABFILE

  cat > "$R/etc/systemd/system/shop@.service" <<'LABFILE'
[Unit]
Description=Ipê Livros catalogue, instance %i
After=network.target

[Service]
User=shop
Environment=SHOP_NAME=shop%i SHOP_PORT=800%i
EnvironmentFile=-/etc/shop/shop.env
ExecStart=/usr/bin/python3 /opt/shop/shop.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
LABFILE
  : > "$R/etc/shop/shop.env"

  python3 - "$R/var/lib/shop/catalogue.db" <<'LABFILE'
import sqlite3, sys, calendar
db = sqlite3.connect(sys.argv[1])
db.execute("DROP TABLE IF EXISTS books")
db.execute("""CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT, author TEXT,
              price_cents INTEGER, stock INTEGER, updated_at INTEGER)""")
t = calendar.timegm((2026, 9, 1, 13, 0, 0))
books = [
    ("Vidas Secas", "Graciliano Ramos", 4990, 12),
    ("Grande Sertão: Veredas", "João Guimarães Rosa", 8990, 4),
    ("A Hora da Estrela", "Clarice Lispector", 3990, 20),
    ("Dom Casmurro", "Machado de Assis", 2990, 31),
    ("Capitães da Areia", "Jorge Amado", 4490, 9),
    ("O Cortiço", "Aluísio Azevedo", 3490, 15),
    ("Macunaíma", "Mário de Andrade", 3990, 7),
    ("Quarto de Despejo", "Carolina Maria de Jesus", 4290, 18),
    ("Torto Arado", "Itamar Vieira Junior", 6990, 25),
    ("O Quinze", "Rachel de Queiroz", 3790, 11),
    ("Memórias Póstumas de Brás Cubas", "Machado de Assis", 3290, 22),
    ("Sagarana", "João Guimarães Rosa", 5490, 6),
]
db.executemany("INSERT INTO books (title, author, price_cents, stock, updated_at) VALUES (?,?,?,?,?)",
               [b + (t,) for b in books])
db.commit()
LABFILE

  cat > "$R/var/www/ipe/index.html" <<'LABFILE'
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>Ipê Livros</title>
<link rel="stylesheet" href="/css/site.css">
<script src="/js/app.js" defer></script>
</head>
<body>
<header><img src="/img/logo.svg" alt="Ipê Livros" width="48" height="48"> <h1>Ipê Livros</h1></header>
<main><p>Livros brasileiros, entregues em todo o país.</p><ul id="books"></ul></main>
</body>
</html>
LABFILE
  cat > "$R/var/www/ipe/css/site.css" <<'LABFILE'
body { font-family: Georgia, serif; max-width: 40rem; margin: 2rem auto; color: #2b2b2b; }
header { display: flex; align-items: center; gap: 1rem; }
h1 { color: #b5527e; margin: 0; }
li { padding: .25rem 0; }
li span { color: #6b6b6b; }
LABFILE
  cat > "$R/var/www/ipe/js/app.js" <<'LABFILE'
// Fills the list from the catalogue API.
fetch('/api/books')
  .then(r => r.json())
  .then(books => {
    const ul = document.getElementById('books');
    for (const b of books) {
      const li = document.createElement('li');
      li.textContent = b.title + ' ';
      const price = document.createElement('span');
      price.textContent = 'R$ ' + (b.price_cents / 100).toFixed(2).replace('.', ',');
      li.append(price);
      ul.append(li);
    }
  });
LABFILE
  cat > "$R/var/www/ipe/img/logo.svg" <<'LABFILE'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="22" fill="#e9a3c4"/><circle cx="24" cy="24" r="8" fill="#b5527e"/></svg>
LABFILE

  mkdir -p "$R$W"
  cat > "$R$W/catalogue.py" <<'LABFILE'
"""The bookshop's database, as a module, for the cache code of lessons 8 to 11.

Every call sleeps QUERY_MS first, as the shop's API does, and counts itself in
`queries`, so a script can say how many times it reached the database."""
import sqlite3, threading, time

DB = "/var/lib/shop/catalogue.db"
QUERY_MS = 120
queries = 0
_lock = threading.Lock()


def get_book(book_id):
    global queries
    time.sleep(QUERY_MS / 1000)
    with _lock:
        queries += 1
    with sqlite3.connect(DB) as db:
        db.row_factory = sqlite3.Row
        row = db.execute("SELECT * FROM books WHERE id = ?", (book_id,)).fetchone()
        return dict(row) if row else None


def set_price(book_id, price_cents):
    with sqlite3.connect(DB) as db:
        db.execute("UPDATE books SET price_cents = ?, updated_at = ? WHERE id = ?",
                   (price_cents, int(time.time()), book_id))
LABFILE

  # Fixed dates, so Last-Modified and nginx's ETag repeat on every run.
  find "$R/var/www/ipe" "$R/opt/shop" "$R$W/catalogue.py" -exec touch -h -d '2026-09-01 10:00:00 -0300' {} +
}

install() { # on the server itself, as root: what lesson 1 tells the student to run
  local user=${SUDO_USER:-ana} home
  home=$(getent passwd "$user" | cut -d: -f6)
  export DEBIAN_FRONTEND=noninteractive
  # shellcheck disable=SC2086
  apt-get update -q && apt-get install -y -q --no-install-recommends $(echo $PACKAGES)
  id shop >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d /var/lib/shop shop
  grep -q ipelivros.example /etc/hosts ||
    printf '127.0.0.1\tipelivros.example www.ipelivros.example static.ipelivros.example\n' >> /etc/hosts
  write_files "" "$home/work"
  chown -R shop: /var/lib/shop
  chown -R "$user": "$home/work"
  # Ubuntu starts every server it installs, and they cannot all have port 80.
  # Stop them all; each lesson starts the ones it uses.
  local booted=; [ -d /run/systemd/system ] && booted=--now
  for s in nginx apache2 caddy redis-server memcached varnish varnishncsa; do
    systemctl disable $booted "$s" >/dev/null 2>&1 || true
  done
  systemctl daemon-reload >/dev/null 2>&1 || true
  systemctl enable $booted shop@1 shop@2 >/dev/null 2>&1
  echo "Ipê Livros is installed. Every web server is stopped; lesson 1 starts them."
}

build() { # the lab's server: a container standing in for the virtual machine
  [ -n "$BASE" ] || exit 1
  if [ ! -x "$BASE/usr/bin/python3" ]; then
    rm -rf "$BASE"
    debootstrap --include=systemd,systemd-sysv,dbus,sudo,curl,ca-certificates,iproute2,less,nano,jq,python3,openssl,netcat-openbsd,locales,tzdata,file \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  echo web > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tweb\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  cp "$0" "$BASE/root/lab.sh"
  nspawn -D "$BASE" --pipe bash -c '
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo "ana ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ana
    systemctl mask console-getty.service >/dev/null 2>&1 || true
    SUDO_USER=ana bash /root/lab.sh install
    sed -i "/listen \[::\]:80/d" /etc/nginx/sites-available/default'
  rm -f "$BASE/root/lab.sh"
}

down() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 0
  rm -f "$PIDFILE"
  [ "$(cat /proc/"$p"/comm 2>/dev/null)" = systemd-nspawn ] || return 0
  kill "$p" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 "$p" 2>/dev/null || break; sleep 0.2; done
  rm -f "$PIDFILE"
}

up() {
  mountpoint -q /run/systemd/nspawn || { mkdir -p /run/systemd/nspawn; mount -t tmpfs tmpfs /run/systemd/nspawn; }
  setsid systemd-nspawn -q -b --console=passive --register=no --keep-unit \
    --private-network --timezone=off -D "$LIVE" --machine web </dev/null >/var/log/servers-cache-lab.log 2>&1 &
  echo $! > "$PIDFILE"
  for _ in $(seq 100); do
    if leader >/dev/null && in_vm systemctl is-system-running --wait >/dev/null 2>&1; then break; fi
    sleep 0.3
  done
  in_vm systemctl is-system-running >/dev/null 2>&1 || in_vm systemctl --failed --no-pager || true
}

stage() { # where each lesson starts: what the lessons before it left behind
  local n=${1:-1}
  [ "$n" -ge 2 ] || return 0
  if [ "$n" -eq 2 ]; then
    # Lesson 1's static site, on port 80, as that lesson wrote it.
    in_vm tee /etc/nginx/sites-available/ipelivros >/dev/null <<'LABFILE'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
LABFILE
  else
    # Lesson 2's site: the static front, and the API behind it, compressed.
    in_vm tee /etc/nginx/sites-available/ipelivros >/dev/null <<'LABFILE'
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
LABFILE
    in_vm tee /etc/nginx/conf.d/gzip.conf >/dev/null <<'LABFILE'
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 256;
gzip_vary on;
LABFILE
  fi
  in_vm ln -sf ../sites-available/ipelivros /etc/nginx/sites-enabled/ipelivros
  in_vm systemctl enable --now nginx >/dev/null 2>&1
  [ "$n" -ge 4 ] || return 0
  stage_tls
}

stage_tls() { # lesson 3's end: Pebble, a certificate from it, and the site on HTTPS
  in_vm bash -c 'mkdir -p /etc/pebble && cd /etc/pebble &&
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 \
      -subj "/CN=Lab ACME API" -addext "subjectAltName=DNS:localhost" \
      -keyout api.key -out api.crt 2>/dev/null && chmod 644 api.key'
  in_vm tee /etc/pebble/pebble.json >/dev/null <<'LABFILE'
{
  "pebble": {
    "listenAddress": "127.0.0.1:14000",
    "managementListenAddress": "127.0.0.1:15000",
    "certificate": "/etc/pebble/api.crt",
    "privateKey": "/etc/pebble/api.key",
    "httpPort": 80,
    "tlsPort": 443,
    "ocspResponderURL": "",
    "externalAccountBindingRequired": false,
    "certificateValidityPeriod": 7776000
  }
}
LABFILE
  in_vm tee /etc/systemd/system/pebble.service >/dev/null <<'LABFILE'
[Unit]
Description=Pebble, Let's Encrypt's ACME server for testing
After=network.target

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=/usr/bin/pebble -config /etc/pebble/pebble.json
User=nobody

[Install]
WantedBy=multi-user.target
LABFILE
  in_vm bash -c 'systemctl daemon-reload && systemctl enable --now pebble >/dev/null 2>&1 && sleep 1 &&
    curl -s --cacert /etc/pebble/api.crt https://localhost:15000/roots/0 > /usr/local/share/ca-certificates/pebble-root.crt &&
    update-ca-certificates >/dev/null 2>&1 &&
    REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot certonly --webroot -w /var/www/ipe \
      -d ipelivros.example -d www.ipelivros.example --server https://localhost:14000/dir \
      --agree-tos -m ana@ipelivros.example --no-eff-email --non-interactive >/dev/null 2>&1'
  in_vm tee /etc/nginx/snippets/ipelivros-tls.conf >/dev/null <<'LABFILE'
ssl_certificate     /etc/letsencrypt/live/ipelivros.example/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ipelivros.example/privkey.pem;
ssl_protocols       TLSv1.2 TLSv1.3;
ssl_session_cache   shared:TLS:10m;
ssl_session_timeout 1d;
LABFILE
  in_vm mkdir -p /etc/letsencrypt/renewal-hooks/deploy
  in_vm tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx >/dev/null <<'LABFILE'
#!/bin/sh
# Run by certbot after every certificate it renews: load the new files.
systemctl reload nginx
LABFILE
  in_vm chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
  in_vm sed -i -e 's/^    listen 80;/    listen 443 ssl;\n    include snippets\/ipelivros-tls.conf;/' /etc/nginx/sites-available/ipelivros
  in_vm tee -a /etc/nginx/sites-available/ipelivros >/dev/null <<'LABFILE'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    location /.well-known/acme-challenge/ {
        root /var/www/ipe;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
LABFILE
  in_vm bash -c 'nginx -t 2>/dev/null && systemctl reload nginx'
}

reset() {
  down
  rm -rf "$LIVE"
  cp -a "$BASE" "$LIVE"
  up
  stage "${1:-1}"
}

case "${1:-}" in
  install) install ;;
  build) build ;;
  reset) reset "${2:-1}" ;;
  up) up ;;
  down) down ;;
  as) shift; in_vm su - ana -c "$*" ;;
  root) shift; in_vm bash -lc "$*" ;;
  *) sed -n '2,60p' "$0"; exit 2 ;;
esac
