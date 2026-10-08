---
title: The bookshop
version: 1
---

The course needs something to serve, and it is a small bookshop called Ipê Livros: a static front, a
page that lists the books, and a catalogue API that the front asks for the list. The API is one
Python file using only the standard library and SQLite, so it installs nothing, and you can read all
of it below.

First a user for it to run as, and the directories it lives in:

```sh
sudo useradd -r -s /usr/sbin/nologin -d /var/lib/shop shop
sudo mkdir -p /opt/shop /var/lib/shop /etc/shop /var/www/ipe/css /var/www/ipe/js /var/www/ipe/img
sudo touch /etc/shop/shop.env
```

Then the files. Copy each one with the button in its corner and paste it into the editor that
`sudo nano` opens on the path written above it; `Ctrl+O` saves and `Ctrl+X` leaves.

`/opt/shop/shop.py`, the API:

```python
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
```

**Every database query sleeps 120 milliseconds before it answers**, `SHOP_QUERY_MS`. A twelve-row
SQLite file answers in microseconds, and a cache in front of it would have nothing to save; the sleep
stands in for a real database under load, and the lessons say so wherever a time is read. Every
answer also carries `X-Served-By`, the name of the copy that gave it, which lesson 2 needs once there
are two.

`/etc/systemd/system/shop@.service`, one unit that runs two copies, `shop@1` on port 8001 and `shop@2`
on 8002:

```ini
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
```

`~/make_catalogue.py`, which creates the database with twelve books, every row dated 1 September
2026:

```python
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
```

And the static front, four small files. `/var/www/ipe/index.html`:

```html
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
```

`/var/www/ipe/css/site.css`:

```css
body { font-family: Georgia, serif; max-width: 40rem; margin: 2rem auto; color: #2b2b2b; }
header { display: flex; align-items: center; gap: 1rem; }
h1 { color: #b5527e; margin: 0; }
li { padding: .25rem 0; }
li span { color: #6b6b6b; }
```

`/var/www/ipe/js/app.js`:

```javascript
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
```

`/var/www/ipe/img/logo.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="22" fill="#e9a3c4"/><circle cx="24" cy="24" r="8" fill="#b5527e"/></svg>
```

Last, the database, its owner, and the two copies of the shop:

```sh
sudo python3 make_catalogue.py /var/lib/shop/catalogue.db
sudo chown -R shop: /var/lib/shop
sudo chmod 2775 /var/lib/shop && sudo chmod 664 /var/lib/shop/catalogue.db
sudo usermod -aG shop $USER
sudo find /var/www/ipe /opt/shop -exec touch -h -d '2026-09-01 10:00:00 -0300' {} +
sudo systemctl daemon-reload
sudo systemctl enable --now shop@1 shop@2
```

The `chmod` and the `usermod` let you, and not only the shop, write the database, which lessons 10 and
11 do; the group takes effect at your next login, so leave the shell with `exit` and open it again.
The `touch` gives every file the same fixed date, **so that the dates and `ETag`s you see match the
ones in this course**; without it they are the moment you saved each file, and nothing else changes.

## Checking it

The transcripts in this course were recorded on a machine called `web`, as a user called `ana`.
Yours says `ubuntu@web` if you used Multipass, and that is the only difference you should see:

```
ana@web:~$ grep PRETTY /etc/os-release; nproc; free -h | head -2
PRETTY_NAME="Ubuntu 24.04 LTS"
4
               total        used        free      shared  buff/cache   available
Mem:            15Gi       646Mi        12Gi        13Mi       2.7Gi        15Gi
ana@web:~$ apt-cache policy nginx apache2 caddy | grep -E '^[a-z]|Installed'
nginx:
  Installed: 1.24.0-2ubuntu7.18
apache2:
  Installed: 2.4.58-1ubuntu8.15
caddy:
  Installed: 2.6.2-6ubuntu0.24.04.3
ana@web:~$ systemctl is-active shop@1 shop@2 nginx apache2 caddy
active
active
inactive
inactive
inactive
ana@web:~$ grep ipelivros /etc/hosts
127.0.0.1	ipelivros.example www.ipelivros.example static.ipelivros.example
```

The memory and the processor count are the recording machine's; yours reports what you gave the
virtual machine. What should match is the rest. **The two copies of the shop are running and every
web server is stopped.**

**What the recording machine did differently**, so that nothing surprises you. It was a container
booted with its own systemd rather than a virtual machine, which behaves the same for everything
this course does. It had no IPv6, so two lines that listen on it were removed: the one in Nginx's
default site that listens on `[::]:80`, and `-l ::1` in `/etc/memcached.conf`, which lesson 9 meets.
Yours keeps both. And `ana` could use `sudo` without typing a password, which keeps the transcripts
free of password prompts.
