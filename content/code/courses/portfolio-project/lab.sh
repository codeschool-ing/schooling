#!/usr/bin/env bash
# loanbook's history, as one script: every lesson of this course that shows the
# project stages it from here, so the repository a transcript was captured in
# is the same one every time, down to the commit hashes.
#
#   bash lab.sh stage N    rebuild ~/loanbook with steps 1 to N committed
#   bash lab.sh write N    write the files of step N into it, and commit nothing
#   bash lab.sh steps      list the steps
#
# THE DATES ARE SET, NOT LIVED. Every commit carries the date written beside it
# below, so the log reads as five weeks of work in June and July 2026 whenever
# it is rebuilt. That is the only thing about the history that is staged: the
# code at each step is the code that step committed, and each one passes the
# tests that existed when it was made.
#
# docs/screenshot.png is a real screenshot of step 18 with seed.py's data,
# taken in Chromium at 900x560; its bytes are below in base64.
set -euo pipefail
REPO=${LOANBOOK:-$HOME/loanbook}
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org


# ---- step 1: Say what loanbook is for
step_1() {
  cat > README.md <<'LOANBOOK_FILE'
# loanbook

The IT room lends projectors, laptops and adapters to teachers, and the only
record of who has what is a paper sheet taped to the door. loanbook replaces
the sheet with one page: what is out, who has it, and when it is due back.
LOANBOOK_FILE
}
commit_1() {
  GIT_AUTHOR_DATE=2026-06-01T09:40:00-03:00 GIT_COMMITTER_DATE=2026-06-01T09:40:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Say what loanbook is for
LOANBOOK_FILE
}

# ---- step 2: Serve a page with nothing on it yet
step_2() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
PORT = 8000


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            return self.file("index.html")
        self.send_error(HTTPStatus.NOT_FOUND)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()
LOANBOOK_FILE
  mkdir -p static
  cat > static/index.html <<'LOANBOOK_FILE'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>loanbook</title>
</head>
<body>
  <h1>Equipment on loan</h1>
  <p>Nothing to list yet.</p>
</body>
</html>
LOANBOOK_FILE
}
commit_2() {
  GIT_AUTHOR_DATE=2026-06-02T10:15:00-03:00 GIT_COMMITTER_DATE=2026-06-02T10:15:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Serve a page with nothing on it yet
LOANBOOK_FILE
}

# ---- step 3: List the equipment from SQLite
step_3() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import sqlite3
import sys
from contextlib import closing
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
"""


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db):
    rows = db.execute("SELECT id, name FROM items ORDER BY name").fetchall()
    return [{"id": r["id"], "name": r["name"]} for r in rows]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.send_error(HTTPStatus.NOT_FOUND)

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  mkdir -p static
  cat > static/index.html <<'LOANBOOK_FILE'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>loanbook</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <h1>Equipment on loan</h1>
  <table>
    <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
    <tbody id="items"></tbody>
  </table>
  <script src="/app.js"></script>
</body>
</html>
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map((item) =>
    `<tr><td>${item.name}</td><td>Available</td><td></td></tr>`).join("");
}

load();
LOANBOOK_FILE
  mkdir -p static
  cat > static/style.css <<'LOANBOOK_FILE'
body { font-family: sans-serif; margin: 2rem; color: #333; }
table { border-collapse: collapse; }
th, td { text-align: left; padding: 0.5rem; border-bottom: 1px solid #ddd; }
input::placeholder { color: #bbb; }
LOANBOOK_FILE
  cat > .gitignore <<'LOANBOOK_FILE'
*.db
__pycache__/
LOANBOOK_FILE
}
commit_3() {
  GIT_AUTHOR_DATE=2026-06-03T14:20:00-03:00 GIT_COMMITTER_DATE=2026-06-03T14:20:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
List the equipment from SQLite

Equipment is added from the command line, python3 app.py add NAME,
because a screen for adding it is not in the first version.
LOANBOOK_FILE
}

# ---- step 4: Lend an item to somebody
step_4() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
"""


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"], "due_on": r["due_on"]}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def lend(db, item_id, borrower, today):
    due = today + timedelta(days=LOAN_DAYS)
    with db:
        db.execute(
            "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
            (item_id, borrower, today.isoformat(), due.isoformat()))
    return {"borrower": borrower, "due_on": due.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.send_error(HTTPStatus.NOT_FOUND)

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/loan", self.path)
        if not m:
            return self.send_error(HTTPStatus.NOT_FOUND)
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
        with closing(connect()) as db:
            result = lend(db, int(m[1]), body.get("borrower"), date.today())
            return self.reply(HTTPStatus.CREATED, result)

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function lend(id, borrower) {
  await fetch(`/api/items/${id}/loan`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ borrower }),
  });
  load();
}

function row(item) {
  if (item.loan) {
    return `<tr><td>${item.name}</td>
      <td>Lent to ${item.loan.borrower} until ${item.loan.due_on}</td><td></td></tr>`;
  }
  return `<tr><td>${item.name}</td><td>Available</td>
    <td><form data-id="${item.id}"><input name="borrower" placeholder="Borrower">
      <button>Lend</button></form></td></tr>`;
}

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map(row).join("");
  for (const form of list.querySelectorAll("form")) {
    form.onsubmit = (e) => {
      e.preventDefault();
      lend(form.dataset.id, form.borrower.value);
    };
  }
}

load();
LOANBOOK_FILE
}
commit_4() {
  GIT_AUTHOR_DATE=2026-06-04T11:05:00-03:00 GIT_COMMITTER_DATE=2026-06-04T11:05:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Lend an item to somebody

A loan lasts seven days from the day it is made.
LOANBOOK_FILE
}

# ---- step 5: Take an item back
step_5() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
"""


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"], "due_on": r["due_on"]}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def lend(db, item_id, borrower, today):
    due = today + timedelta(days=LOAN_DAYS)
    with db:
        db.execute(
            "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
            (item_id, borrower, today.isoformat(), due.isoformat()))
    return {"borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    with db:
        db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                   (today.isoformat(), item_id))
    return {"returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.send_error(HTTPStatus.NOT_FOUND)

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.send_error(HTTPStatus.NOT_FOUND)
        item_id, action = int(m[1]), m[2]
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
        with closing(connect()) as db:
            if action == "loan":
                result = lend(db, item_id, body.get("borrower"), date.today())
                return self.reply(HTTPStatus.CREATED, result)
            return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function send(url, body) {
  await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  load();
}

function row(item) {
  if (item.loan) {
    return `<tr><td>${item.name}</td>
      <td>Lent to ${item.loan.borrower} until ${item.loan.due_on}</td>
      <td><button data-id="${item.id}">Return</button></td></tr>`;
  }
  return `<tr><td>${item.name}</td><td>Available</td>
    <td><form data-id="${item.id}"><input name="borrower" placeholder="Borrower">
      <button>Lend</button></form></td></tr>`;
}

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map(row).join("");
  for (const form of list.querySelectorAll("form")) {
    form.onsubmit = (e) => {
      e.preventDefault();
      send(`/api/items/${form.dataset.id}/loan`, { borrower: form.borrower.value });
    };
  }
  for (const button of list.querySelectorAll("td > button")) {
    button.onclick = () => send(`/api/items/${button.dataset.id}/return`);
  }
}

load();
LOANBOOK_FILE
}
commit_5() {
  GIT_AUTHOR_DATE=2026-06-05T16:30:00-03:00 GIT_COMMITTER_DATE=2026-06-05T16:30:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Take an item back
LOANBOOK_FILE
  GIT_COMMITTER_DATE=2026-06-05T16:30:00-03:00 git tag -a v0.1.0 -m 'The skeleton: list, lend and take back, end to end'
}

# ---- step 6: Refuse to lend an item that is already out
step_6() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"], "due_on": r["due_on"]}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.send_error(HTTPStatus.NOT_FOUND)

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.send_error(HTTPStatus.NOT_FOUND)
        item_id, action = int(m[1]), m[2]
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
        try:
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function send(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) alert((await res.json()).error);
  load();
}

function row(item) {
  if (item.loan) {
    return `<tr><td>${item.name}</td>
      <td>Lent to ${item.loan.borrower} until ${item.loan.due_on}</td>
      <td><button data-id="${item.id}">Return</button></td></tr>`;
  }
  return `<tr><td>${item.name}</td><td>Available</td>
    <td><form data-id="${item.id}"><input name="borrower" placeholder="Borrower">
      <button>Lend</button></form></td></tr>`;
}

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map(row).join("");
  for (const form of list.querySelectorAll("form")) {
    form.onsubmit = (e) => {
      e.preventDefault();
      send(`/api/items/${form.dataset.id}/loan`, { borrower: form.borrower.value });
    };
  }
  for (const button of list.querySelectorAll("td > button")) {
    button.onclick = () => send(`/api/items/${button.dataset.id}/return`);
  }
}

load();
LOANBOOK_FILE
}
commit_6() {
  GIT_AUTHOR_DATE=2026-06-09T10:10:00-03:00 GIT_COMMITTER_DATE=2026-06-09T10:10:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Refuse to lend an item that is already out

Two people could lend the same projector from two browsers, and the
list then showed it twice. A partial unique index allows one open loan
per item, so the database refuses the second one even when both
requests arrive together. The handler turns that refusal into a 409
with a sentence the page shows.

Closes #3
LOANBOOK_FILE
}

# ---- step 7: Test the loan rules
step_7() {
  cat > test_app.py <<'LOANBOOK_FILE'
import unittest
from datetime import date

import app

TODAY = date(2026, 7, 6)


class LoanRules(unittest.TestCase):
    def setUp(self):
        self.db = app.connect(":memory:")
        self.db.execute("INSERT INTO items (id, name) VALUES (1, 'Projector 1')")

    def test_a_lent_item_shows_who_has_it(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        loan = app.items(self.db)[0]["loan"]
        self.assertEqual(loan["borrower"], "Bruno")
        self.assertEqual(loan["due_on"], "2026-07-13")

    def test_an_item_cannot_be_lent_twice(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(refused.exception.status, 409)
        self.assertIn("already lent to Bruno", refused.exception.message)

    def test_a_returned_item_can_be_lent_again(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        app.give_back(self.db, 1, TODAY)
        app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(app.items(self.db)[0]["loan"]["borrower"], "Carla")

    def test_an_item_that_is_in_cannot_come_back(self):
        with self.assertRaises(app.Refused) as refused:
            app.give_back(self.db, 1, TODAY)
        self.assertEqual(refused.exception.status, 409)

    def test_an_unknown_item_is_not_found(self):
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 99, "Bruno", TODAY)
        self.assertEqual(refused.exception.status, 404)


if __name__ == "__main__":
    unittest.main()
LOANBOOK_FILE
}
commit_7() {
  GIT_AUTHOR_DATE=2026-06-10T15:45:00-03:00 GIT_COMMITTER_DATE=2026-06-10T15:45:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Test the loan rules
LOANBOOK_FILE
}

# ---- step 8: Answer every error as JSON
step_8() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"], "due_on": r["due_on"]}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})
        item_id, action = int(m[1]), m[2]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except json.JSONDecodeError:
            self.reply(HTTPStatus.BAD_REQUEST, {"error": "The body is not JSON."})
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
}
commit_8() {
  GIT_AUTHOR_DATE=2026-06-11T09:55:00-03:00 GIT_COMMITTER_DATE=2026-06-11T09:55:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Answer every error as JSON

A path that does not exist answered with an HTML page, and a body that
was not JSON dropped the connection with a traceback in the log. The
page reads the error field of a JSON answer, so every answer is JSON.
LOANBOOK_FILE
}

# ---- step 9: Say what to do when there is nothing to lend
step_9() {
  mkdir -p static
  cat > static/index.html <<'LOANBOOK_FILE'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>loanbook</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <h1>Equipment on loan</h1>
  <table>
    <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
    <tbody id="items"></tbody>
  </table>
  <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
    <code>python3 app.py add "Projector 1"</code>.</p>
  <script src="/app.js"></script>
</body>
</html>
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function send(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) alert((await res.json()).error);
  load();
}

function row(item) {
  if (item.loan) {
    return `<tr><td>${item.name}</td>
      <td>Lent to ${item.loan.borrower} until ${item.loan.due_on}</td>
      <td><button data-id="${item.id}">Return</button></td></tr>`;
  }
  return `<tr><td>${item.name}</td><td>Available</td>
    <td><form data-id="${item.id}"><input name="borrower" placeholder="Borrower">
      <button>Lend</button></form></td></tr>`;
}

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map(row).join("");
  document.getElementById("empty").hidden = items.length > 0;
  for (const form of list.querySelectorAll("form")) {
    form.onsubmit = (e) => {
      e.preventDefault();
      send(`/api/items/${form.dataset.id}/loan`, { borrower: form.borrower.value });
    };
  }
  for (const button of list.querySelectorAll("td > button")) {
    button.onclick = () => send(`/api/items/${button.dataset.id}/return`);
  }
}

load();
LOANBOOK_FILE
}
commit_9() {
  GIT_AUTHOR_DATE=2026-06-12T17:20:00-03:00 GIT_COMMITTER_DATE=2026-06-12T17:20:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Say what to do when there is nothing to lend
LOANBOOK_FILE
}

# ---- step 10: Mark a loan overdue the day after it is due
step_10() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db, today):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"],
                    "due_on": r["due_on"], "overdue": r["due_on"] < today.isoformat()}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db, date.today()))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})
        item_id, action = int(m[1]), m[2]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except json.JSONDecodeError:
            self.reply(HTTPStatus.BAD_REQUEST, {"error": "The body is not JSON."})
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");

async function send(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) alert((await res.json()).error);
  load();
}

function row(item) {
  if (item.loan) {
    return `<tr><td>${item.name}</td>
      <td>Lent to ${item.loan.borrower} until ${item.loan.due_on}${item.loan.overdue ? " (overdue)" : ""}</td>
      <td><button data-id="${item.id}">Return</button></td></tr>`;
  }
  return `<tr><td>${item.name}</td><td>Available</td>
    <td><form data-id="${item.id}"><input name="borrower" placeholder="Borrower">
      <button>Lend</button></form></td></tr>`;
}

async function load() {
  const res = await fetch("/api/items");
  const items = await res.json();
  list.innerHTML = items.map(row).join("");
  document.getElementById("empty").hidden = items.length > 0;
  for (const form of list.querySelectorAll("form")) {
    form.onsubmit = (e) => {
      e.preventDefault();
      send(`/api/items/${form.dataset.id}/loan`, { borrower: form.borrower.value });
    };
  }
  for (const button of list.querySelectorAll("td > button")) {
    button.onclick = () => send(`/api/items/${button.dataset.id}/return`);
  }
}

load();
LOANBOOK_FILE
  cat > test_app.py <<'LOANBOOK_FILE'
import unittest
from datetime import date, timedelta

import app

TODAY = date(2026, 7, 6)


class LoanRules(unittest.TestCase):
    def setUp(self):
        self.db = app.connect(":memory:")
        self.db.execute("INSERT INTO items (id, name) VALUES (1, 'Projector 1')")

    def test_a_lent_item_shows_who_has_it(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        loan = app.items(self.db, TODAY)[0]["loan"]
        self.assertEqual(loan["borrower"], "Bruno")
        self.assertEqual(loan["due_on"], "2026-07-13")

    def test_an_item_cannot_be_lent_twice(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(refused.exception.status, 409)
        self.assertIn("already lent to Bruno", refused.exception.message)

    def test_a_returned_item_can_be_lent_again(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        app.give_back(self.db, 1, TODAY)
        app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(app.items(self.db, TODAY)[0]["loan"]["borrower"], "Carla")

    def test_an_item_that_is_in_cannot_come_back(self):
        with self.assertRaises(app.Refused) as refused:
            app.give_back(self.db, 1, TODAY)
        self.assertEqual(refused.exception.status, 409)

    def test_a_loan_is_overdue_the_day_after_it_is_due(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        due = TODAY + timedelta(days=app.LOAN_DAYS)
        self.assertFalse(app.items(self.db, due)[0]["loan"]["overdue"])
        self.assertTrue(app.items(self.db, due + timedelta(days=1))[0]["loan"]["overdue"])

    def test_an_unknown_item_is_not_found(self):
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 99, "Bruno", TODAY)
        self.assertEqual(refused.exception.status, 404)


if __name__ == "__main__":
    unittest.main()
LOANBOOK_FILE
}
commit_10() {
  GIT_AUTHOR_DATE=2026-06-15T11:30:00-03:00 GIT_COMMITTER_DATE=2026-06-15T11:30:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Mark a loan overdue the day after it is due

Closes #5
LOANBOOK_FILE
  GIT_COMMITTER_DATE=2026-06-15T11:30:00-03:00 git tag -a v0.2.0 -m 'The rules: one loan at a time, overdue after seven days'
}

# ---- step 11: Label every field and announce what happened
step_11() {
  mkdir -p static
  cat > static/index.html <<'LOANBOOK_FILE'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>loanbook</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Equipment on loan</h1>
    <p id="message" role="status"></p>
    <table>
      <thead><tr><th scope="col">Item</th><th scope="col">Status</th><th scope="col">Action</th></tr></thead>
      <tbody id="items"></tbody>
    </table>
    <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
      <code>python3 app.py add "Projector 1"</code>.</p>
  </main>
  <script src="/app.js"></script>
</body>
</html>
LOANBOOK_FILE
  mkdir -p static
  cat > static/app.js <<'LOANBOOK_FILE'
const list = document.getElementById("items");
const message = document.getElementById("message");

async function send(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body && JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error);
  return data;
}

function row(item) {
  const tr = document.createElement("tr");
  const name = document.createElement("th");
  name.scope = "row";
  name.textContent = item.name;
  const status = document.createElement("td");
  const action = document.createElement("td");
  if (item.loan) {
    const due = document.createElement("time");
    due.dateTime = due.textContent = item.loan.due_on;
    status.append(`Lent to ${item.loan.borrower} until `, due);
    if (item.loan.overdue) {
      const late = document.createElement("strong");
      late.textContent = "overdue";
      status.append(" ", late);
    }
    const back = document.createElement("button");
    back.textContent = `Return ${item.name}`;
    back.onclick = () => act(`/api/items/${item.id}/return`);
    action.append(back);
  } else {
    status.textContent = "Available";
    const form = document.createElement("form");
    const id = `borrower-${item.id}`;
    form.innerHTML = `<label for="${id}">Lend ${item.name} to</label>
      <input id="${id}" name="borrower" autocomplete="name" required>
      <button>Lend</button>`;
    form.onsubmit = (e) => {
      e.preventDefault();
      act(`/api/items/${item.id}/loan`, { borrower: form.borrower.value });
    };
    action.append(form);
  }
  tr.append(name, status, action);
  return tr;
}

async function act(url, body) {
  try {
    const done = await send("POST", url, body);
    message.textContent = done.borrower
      ? `${done.item} lent to ${done.borrower} until ${done.due_on}.`
      : `${done.item} is back.`;
  } catch (e) {
    message.textContent = e.message;
  }
  await load();
}

async function load() {
  const items = await send("GET", "/api/items");
  list.replaceChildren(...items.map(row));
  document.getElementById("empty").hidden = items.length > 0;
}

load().catch(() => {
  message.textContent = "The server did not answer. Reload the page to try again.";
});
LOANBOOK_FILE
  mkdir -p static
  cat > static/style.css <<'LOANBOOK_FILE'
body { font: 1rem/1.5 system-ui, sans-serif; margin: 0; color: #1b1b1b; background: #fff; }
main { max-width: 48rem; margin: 0 auto; padding: 1rem; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: 0.5rem; border-bottom: 1px solid #767676; vertical-align: top; }
label { display: block; }
time { white-space: nowrap; }
input, button { font: inherit; padding: 0.25rem 0.5rem; }
:focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
#message:empty { display: none; }
#message { padding: 0.5rem; border-left: 4px solid #1a5fb4; background: #eef3fb; }

LOANBOOK_FILE
}
commit_11() {
  GIT_AUTHOR_DATE=2026-06-17T14:05:00-03:00 GIT_COMMITTER_DATE=2026-06-17T14:05:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Label every field and announce what happened

The borrower field had only a placeholder, which disappears once you
type and which a screen reader may not announce. Each field now has a
label naming the item, results are announced in a status region instead
of alert(), and every Return button says what it returns. Names are set
with textContent, so a borrower typed as <b>Rui</b> is shown as typed
rather than drawn as markup.
LOANBOOK_FILE
}

# ---- step 12: Fit the table on a phone
step_12() {
  mkdir -p static
  cat > static/style.css <<'LOANBOOK_FILE'
body { font: 1rem/1.5 system-ui, sans-serif; margin: 0; color: #1b1b1b; background: #fff; }
main { max-width: 48rem; margin: 0 auto; padding: 1rem; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: 0.5rem; border-bottom: 1px solid #767676; vertical-align: top; }
label { display: block; }
time { white-space: nowrap; }
input, button { font: inherit; padding: 0.25rem 0.5rem; }
:focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
#message:empty { display: none; }
#message { padding: 0.5rem; border-left: 4px solid #1a5fb4; background: #eef3fb; }

@media (max-width: 36rem) {
  thead { display: none; }
  tr, th, td { display: block; }
  tr { border-bottom: 1px solid #767676; padding: 0.5rem 0; }
  th, td { border: 0; padding: 0.25rem 0; }
}
LOANBOOK_FILE
}
commit_12() {
  GIT_AUTHOR_DATE=2026-06-18T10:40:00-03:00 GIT_COMMITTER_DATE=2026-06-18T10:40:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Fit the table on a phone

Below 36rem each row becomes a block, so nothing scrolls sideways at 320
pixels.
LOANBOOK_FILE
}

# ---- step 13: Refuse a borrower made of spaces
step_13() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = str(HERE / "loanbook.db")
PORT = 8000
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db, today):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"],
                    "due_on": r["due_on"], "overdue": r["due_on"] < today.isoformat()}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    borrower = (borrower or "").strip()
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db, date.today()))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})
        item_id, action = int(m[1]), m[2]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except json.JSONDecodeError:
            self.reply(HTTPStatus.BAD_REQUEST, {"error": "The body is not JSON."})
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  cat > test_app.py <<'LOANBOOK_FILE'
import unittest
from datetime import date, timedelta

import app

TODAY = date(2026, 7, 6)


class LoanRules(unittest.TestCase):
    def setUp(self):
        self.db = app.connect(":memory:")
        self.db.execute("INSERT INTO items (id, name) VALUES (1, 'Projector 1')")

    def test_a_lent_item_shows_who_has_it(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        loan = app.items(self.db, TODAY)[0]["loan"]
        self.assertEqual(loan["borrower"], "Bruno")
        self.assertEqual(loan["due_on"], "2026-07-13")

    def test_an_item_cannot_be_lent_twice(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(refused.exception.status, 409)
        self.assertIn("already lent to Bruno", refused.exception.message)

    def test_a_returned_item_can_be_lent_again(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        app.give_back(self.db, 1, TODAY)
        app.lend(self.db, 1, "Carla", TODAY)
        self.assertEqual(app.items(self.db, TODAY)[0]["loan"]["borrower"], "Carla")

    def test_an_item_that_is_in_cannot_come_back(self):
        with self.assertRaises(app.Refused) as refused:
            app.give_back(self.db, 1, TODAY)
        self.assertEqual(refused.exception.status, 409)

    def test_a_borrower_made_of_spaces_is_refused(self):
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 1, "   ", TODAY)
        self.assertEqual(refused.exception.status, 400)

    def test_a_loan_is_overdue_the_day_after_it_is_due(self):
        app.lend(self.db, 1, "Bruno", TODAY)
        due = TODAY + timedelta(days=app.LOAN_DAYS)
        self.assertFalse(app.items(self.db, due)[0]["loan"]["overdue"])
        self.assertTrue(app.items(self.db, due + timedelta(days=1))[0]["loan"]["overdue"])

    def test_an_unknown_item_is_not_found(self):
        with self.assertRaises(app.Refused) as refused:
            app.lend(self.db, 99, "Bruno", TODAY)
        self.assertEqual(refused.exception.status, 404)


if __name__ == "__main__":
    unittest.main()
LOANBOOK_FILE
}
commit_13() {
  GIT_AUTHOR_DATE=2026-06-22T16:15:00-03:00 GIT_COMMITTER_DATE=2026-06-22T16:15:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Refuse a borrower made of spaces

The test came first, and it failed: "   " was accepted as a name.
LOANBOOK_FILE
}

# ---- step 14: Read the database path and port from the environment
step_14() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import os
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = os.environ.get("LOANBOOK_DB", str(HERE / "loanbook.db"))
PORT = int(os.environ.get("LOANBOOK_PORT", "8000"))
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db, today):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"],
                    "due_on": r["due_on"], "overdue": r["due_on"] < today.isoformat()}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    borrower = (borrower or "").strip()
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db, date.today()))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})
        item_id, action = int(m[1]), m[2]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except json.JSONDecodeError:
            self.reply(HTTPStatus.BAD_REQUEST, {"error": "The body is not JSON."})
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
  cat > .gitignore <<'LOANBOOK_FILE'
*.db
.env
__pycache__/
LOANBOOK_FILE
}
commit_14() {
  GIT_AUTHOR_DATE=2026-06-24T09:25:00-03:00 GIT_COMMITTER_DATE=2026-06-24T09:25:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Read the database path and port from the environment

The container keeps the database in a volume, so its path cannot be
the directory the code is in.
LOANBOOK_FILE
}

# ---- step 15: Answer /healthz so a monitor can ask
step_15() {
  cat > app.py <<'LOANBOOK_FILE'
"""loanbook: who has which piece of equipment, and until when."""
import json
import os
import re
import sqlite3
import sys
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DB = os.environ.get("LOANBOOK_DB", str(HERE / "loanbook.db"))
PORT = int(os.environ.get("LOANBOOK_PORT", "8000"))
LOAN_DAYS = 7

SCHEMA = """
CREATE TABLE IF NOT EXISTS items (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY,
  item_id     INTEGER NOT NULL REFERENCES items(id),
  borrower    TEXT NOT NULL,
  lent_on     TEXT NOT NULL,
  due_on      TEXT NOT NULL,
  returned_on TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_loan
  ON loans(item_id) WHERE returned_on IS NULL;
"""


class Refused(Exception):
    """A request the rules say no to, with the status and the sentence to show."""

    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def connect(path=DB):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def items(db, today):
    rows = db.execute("""
        SELECT i.id, i.name, l.borrower, l.lent_on, l.due_on
        FROM items i
        LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL
        ORDER BY i.name""").fetchall()
    out = []
    for r in rows:
        loan = None
        if r["borrower"]:
            loan = {"borrower": r["borrower"], "lent_on": r["lent_on"],
                    "due_on": r["due_on"], "overdue": r["due_on"] < today.isoformat()}
        out.append({"id": r["id"], "name": r["name"], "loan": loan})
    return out


def item_named(db, item_id):
    row = db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)).fetchone()
    if row is None:
        raise Refused(HTTPStatus.NOT_FOUND, f"There is no item {item_id}.")
    return row


def lend(db, item_id, borrower, today):
    borrower = (borrower or "").strip()
    if not borrower:
        raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
    item = item_named(db, item_id)
    due = today + timedelta(days=LOAN_DAYS)
    try:
        with db:
            db.execute(
                "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (?, ?, ?, ?)",
                (item_id, borrower, today.isoformat(), due.isoformat()))
    except sqlite3.IntegrityError:
        who = db.execute("SELECT borrower, due_on FROM loans WHERE item_id = ? AND returned_on IS NULL",
                         (item_id,)).fetchone()
        raise Refused(HTTPStatus.CONFLICT,
                      f"{item['name']} is already lent to {who['borrower']} until {who['due_on']}.")
    return {"item": item["name"], "borrower": borrower, "due_on": due.isoformat()}


def give_back(db, item_id, today):
    item = item_named(db, item_id)
    with db:
        done = db.execute("UPDATE loans SET returned_on = ? WHERE item_id = ? AND returned_on IS NULL",
                          (today.isoformat(), item_id)).rowcount
    if not done:
        raise Refused(HTTPStatus.CONFLICT, f"{item['name']} is not out, so it cannot come back.")
    return {"item": item["name"], "returned_on": today.isoformat()}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            with closing(connect()) as db:
                db.execute("SELECT 1")
            return self.reply(HTTPStatus.OK, {"ok": True})
        if self.path == "/api/items":
            with closing(connect()) as db:
                return self.reply(HTTPStatus.OK, items(db, date.today()))
        static = {"/": "index.html", "/app.js": "app.js", "/style.css": "style.css"}
        if self.path in static:
            return self.file(static[self.path])
        self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})

    def do_POST(self):
        m = re.fullmatch(r"/api/items/(\d+)/(loan|return)", self.path)
        if not m:
            return self.reply(HTTPStatus.NOT_FOUND, {"error": f"Nothing lives at {self.path}."})
        item_id, action = int(m[1]), m[2]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            with closing(connect()) as db:
                if action == "loan":
                    result = lend(db, item_id, body.get("borrower"), date.today())
                    return self.reply(HTTPStatus.CREATED, result)
                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))
        except json.JSONDecodeError:
            self.reply(HTTPStatus.BAD_REQUEST, {"error": "The body is not JSON."})
        except Refused as r:
            self.reply(r.status, {"error": r.message})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def file(self, name):
        body = (HERE / "static" / name).read_bytes()
        kind = {"html": "text/html", "js": "text/javascript", "css": "text/css"}[name.rsplit(".", 1)[1]]
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.command} {self.path} {args[1]}\n")


def main(argv):
    if argv[1:2] == ["add"] and len(argv) == 3:
        with closing(connect()) as db, db:
            db.execute("INSERT INTO items (name) VALUES (?)", (argv[2],))
        return print(f"added {argv[2]}")
    connect().close()
    print(f"loanbook on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main(sys.argv)
LOANBOOK_FILE
}
commit_15() {
  GIT_AUTHOR_DATE=2026-06-25T13:50:00-03:00 GIT_COMMITTER_DATE=2026-06-25T13:50:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Answer /healthz so a monitor can ask
LOANBOOK_FILE
}

# ---- step 16: Build and run in a container
step_16() {
  cat > Containerfile <<'LOANBOOK_FILE'
FROM docker.io/library/python:3.12-slim
WORKDIR /app
COPY app.py seed.py ./
COPY static ./static
ENV LOANBOOK_DB=/data/loanbook.db LOANBOOK_PORT=8000
USER 1000
EXPOSE 8000
CMD ["python3", "app.py"]
LOANBOOK_FILE
}
commit_16() {
  GIT_AUTHOR_DATE=2026-06-26T15:10:00-03:00 GIT_COMMITTER_DATE=2026-06-26T15:10:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Build and run in a container
LOANBOOK_FILE
}

# ---- step 17: Deploy with systemd and Caddy
step_17() {
  mkdir -p deploy
  cat > deploy/loanbook.container <<'LOANBOOK_FILE'
[Unit]
Description=loanbook, the equipment loan register

[Container]
Image=localhost/loanbook:latest
PublishPort=127.0.0.1:8000:8000
Volume=loanbook-data:/data:U
HealthCmd=python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')"
HealthInterval=30s

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
LOANBOOK_FILE
  mkdir -p deploy
  cat > deploy/Caddyfile <<'LOANBOOK_FILE'
loans.lab {
	tls internal
	reverse_proxy 127.0.0.1:8000
}
LOANBOOK_FILE
}
commit_17() {
  GIT_AUTHOR_DATE=2026-06-29T18:00:00-03:00 GIT_COMMITTER_DATE=2026-06-29T18:00:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Deploy with systemd and Caddy
LOANBOOK_FILE
  GIT_COMMITTER_DATE=2026-06-29T18:00:00-03:00 git tag -a v0.3.0 -m 'Deployed: a container under systemd, behind Caddy'
}

# ---- step 18: Seed a week that looks real
step_18() {
  cat > seed.py <<'LOANBOOK_FILE'
"""Fill an empty loanbook with a week that looks like a real one."""
from contextlib import closing
from datetime import date, timedelta

import app

ITEMS = ["Projector 1", "Projector 2", "Laptop 03", "Laptop 07", "HDMI adapter A",
         "Document camera", "Tripod", "Conference speaker"]
LOANS = [  # item, borrower, how many days ago it went out
    ("Projector 2", "Beatriz Nunes", 2),
    ("Laptop 03", "Carlos Mendes", 9),
    ("Document camera", "Dora Okafor", 1),
    ("Tripod", "Eduardo Lins", 4),
]

with closing(app.connect()) as db:
    if db.execute("SELECT count(*) FROM items").fetchone()[0]:
        raise SystemExit("loanbook already has items; seed only an empty one")
    with db:
        db.executemany("INSERT INTO items (name) VALUES (?)", [(n,) for n in ITEMS])
    ids = {r["name"]: r["id"] for r in db.execute("SELECT id, name FROM items")}
    for name, borrower, ago in LOANS:
        app.lend(db, ids[name], borrower, date.today() - timedelta(days=ago))
    print(f"seeded {len(ITEMS)} items, {len(LOANS)} of them out")
LOANBOOK_FILE
}
commit_18() {
  GIT_AUTHOR_DATE=2026-07-01T10:35:00-03:00 GIT_COMMITTER_DATE=2026-07-01T10:35:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Seed a week that looks real
LOANBOOK_FILE
}

# ---- step 19: Explain how to run it and why it is built this way
step_19() {
  cat > README.md <<'LOANBOOK_FILE'
# loanbook

The IT room of a secondary school lends projectors, laptops and adapters to
teachers, and the record of who had what was a paper sheet taped to the door.
loanbook replaces the sheet with one page: what is out, who has it, and when
it is due back.

![The list: four items out, one of them overdue](docs/screenshot.png)

## What it does

- Lists the equipment, and for each item on loan, who has it and until when.
- Lends an item for seven days, and refuses to lend one that is already out.
- Takes an item back.
- Marks a loan overdue the day after it was due.

## Run it

It needs Python 3.12 or newer and nothing else.

```sh
git clone https://example.org/ana/loanbook.git
cd loanbook
python3 seed.py     # optional: a week of loans that looks like a real one
python3 app.py
```

Then open http://127.0.0.1:8000. Equipment is added from the command line:
`python3 app.py add "Projector 1"`. The tests run with `python3 -m unittest`.

## Deploy

The server runs it in a container, kept up by systemd and served over HTTPS
by Caddy. Both files are in `deploy/`.

```sh
sudo podman build -t loanbook .
sudo cp deploy/loanbook.container /etc/containers/systemd/
sudo systemctl daemon-reload && sudo systemctl start loanbook
sudo cp deploy/Caddyfile /etc/caddy/Caddyfile && sudo systemctl reload caddy
```

`GET /healthz` answers `{"ok": true}` when the server can reach its database.

## Decisions

- **The database refuses a second loan, not the code.** A partial unique
  index allows one open loan per item, so two people pressing Lend at the same
  moment cannot both succeed. A check in Python would read "available" twice
  and write two loans.
- **SQLite, not a database server.** One room, a few dozen items, one server:
  a file is enough, and a backup is a copy of it. If several schools shared
  one instance, this is the first thing to change.
- **No accounts.** The borrower is a name typed in. Everybody who uses it works
  in the same building, and a login would have doubled the first version. The
  cost is that anybody who can open the page can lend.
- **The standard library only.** Nothing to install or upgrade; the price is
  about fifteen lines of routing written by hand.

## Not yet

E-mail reminders, a screen for adding equipment, and a history of past loans.
Each one waited because the first version was worth showing without it.

## Licence

MIT. See `LICENSE`.
LOANBOOK_FILE
  mkdir -p docs
  base64 -d > docs/screenshot.png <<'LOANBOOK_FILE'
iVBORw0KGgoAAAANSUhEUgAAA+gAAANsCAIAAABH4BV9AAAQAElEQVR4nOz9TYwaZ6I3fNccvVJx
NFKhWYBzpMLzjMDJEcRzBErmcWmcMa3EpjVO05LjamkSWCSwmMAmzSzc1Ytp+iy67MVUe1PtLCBZ
wHhuNYmlZo5HXSe2XPcZj+roTkTrkQN6Xgc0kmHxGlaUNDpVK79XFdAN/W3Hjhv7/1POHDfUx1Uf
XPzruq4q/j+PHj2iAAAAAADgaPv/UAAAAAAAcOQhuAMAAAAAjAEEdwAAAACAMYDgDgAAAAAwBhDc
AQAAAADGAII7AAAAAMAYQHAHAAAAABgDCO4AAAAAAGMAwR0AAAAAYAwguAMAAAAAjAEEdwAAAACA
MYDgDgAAAAAwBhDcAQAAAADGAII7AAAAAMAYQHAHAAAAABgDCO4AAAAAAGMAwR0AAAAAYAwguAMA
AAAAjAEEdwAAAACAMYDgDgAAAAAwBhDcAQAAAADGAII7AAAAAMAYQHAHAAAAABgDCO4AAAAAAGMA
wR0AAAAAYAwguAMAAAAAjAEEdwAAAACAMYDgDgAAAAAwBhDcAQAAAADGAII7AAAAAMAYQHAHAAAA
ABgDCO4AAAAAAGMAwR0AAAAAYAwguAMAAAAAjAEEdwAAAACAMYDgDgAAAAAwBhDcAQAAAADGAII7
AAAAAMAYQHAHAAAAABgDCO4AAAAAAGMAwR0AAAAAYAwguAMAAAAAjAEEdwAAAACAMYDgDgAAAAAw
BhDcAQAAAADGAII7AAAAAMAYQHAHAAAAABgD/0QBHJJRlc+xI6bkqkEBPIYdZ5EXZxEAAMDhoMX9
mTPqhXhE0MzDz+FPlUvzIScFLzijeadU1prdzRecgenYdABHHgAAAHaD4A7wvJgtNSfmG1svMGFf
NBJwOigAAACAHRDcAQAAAADGAII7HJrDFUoKqfrQyA4f50LrMAAAAMAPAsH9ufBGYhEvs8ebTs8E
S1NHkZubSXMUAAAAADwHCO7PgyvAZ+Yn3dTj6lbXS4XSmqpttHTa5fUHuEk+zk8H3FR7LRFJK52h
VURzysrWKox6Lh7JDt8h602Uyovc8H2QO6fZdpesUZWjEbE2NEtQUErpgOPACYz6HVLwslqpNqyS
+0NcmI/Ho5xnl/b6bmWJj67sXAjVrpRzuZKqVWodk2H9oXA8neaHFmHtnVWydyq1Roey9k4gFI7O
8JP73+xptCuKNVOj1WzWW42OTtEMy3o9Ph9ZwzQfCbl361PYe0utUhbKVilbOillIBAIRma2bWrT
Plr6zsXqaobzZYZf8QtKeWgPH5LR1MrlNa3SqjebraGN8nhYbyiy5z7panMRvtjaeoEJS0pxxmMt
r1QoWMfP3qpgKBTgyGL22DlPz/DBIRvS0k2KcXlZn70dex8da1OaFU3VNOuEa7bbHYtundnkY+Nl
e/uBmwiHOd+uO2LnDeWDj0u3ulYslNe1/kkWCoX84Wg8OuHDHcUAAPADQHAfE0Z9TZwV8hubac/s
NDZU8l8xVxJWxCh1ZOnVVSGVKW3dgml2alqZ/LciR7LLUvJQj8/paLKQEtXNKxO9VVOLgloqxOSV
7KTP0a7kMqmsupU5+3unnM/xckmc9uya79qanE6JWmf0VVNvNTbIf5pSyoveqJSXZnyHyqf69mNE
SqmR/5RSsZQt5pI/yIOCjOYdKZNe0bZdFgw2ilLLpXzWGxVXxPihHl9jtqurYkooNTZTrN7aUMl/
5WIhIhXlQ+6bx0cOTmb4kA/W3mnUyH+Uah0dV1hYkdLcjkvg9p0sHy+1dlmq2Zt9g6LKxRWKCSbk
FWHCc6hNMJt3ljKZlaHTpdPQlIZ1eFcTxfwi9/hX4gAAAI8Hz3EfB0Z9NR1LDyXCYR1VjCWySvsx
njf5w9EruXRsOLUPayhZPragtQ9aSGttjud3RjjCrBWTKXFdKwiJ4dQ+MnNJyBR3eU640VybJUvV
OtS+GuUMn8wd4jnjrfVsLLLXMdK17Jx058AN/d7IiSLE4jtS+w6NssAn5Ur3gMnIpUhJ4KOZodQ+
rKUIs/mDF/IEjPb6Qiy26yEfYZ/7C3faT/oYeH0jH48J682D5+9oUiwSX9n9dDE38rPZtSYFAADw
jKHF/XnoVEvSUmX3Me5ODxflR9oAu5W8ICitfZZn1pQydSQ1lD1Ce58VeUSuvLzvuKGO1UC6p1o+
yVP70TVZVqMrI6toa2Jil+sJ2sWytN5ojQTfjppNCK49m+0HU23sfw1QK66UZ7hk4BmOLWnfsZvG
Dzexbu0BpiTH920xb2nafgsxN6xdm5/2UE8TOeHTmXztcFei5AxKp93FXHrv/gyacblcDEOT1vpO
q7P9oqZRykqR0PIBI9f0mlbb7/1WWS4kw/j1BQAAeLYQ3J+LhkL66ffA6qHocHBvVwqF7T/f5Aqn
xEyc87usYScFUTi4jfU5ov18djEd8bO02aop8kK2NJLJWuW8kg7HDxpx4eJiaZ5j6Y5alIu7ZmQ2
nEhGOZbs3IJcGmn57mjlSntyK5p1K7mF0WBIyiheFqK9IdP2aJORMRGtkiRHucsTBw6G6JeBhH+t
lBstpllRtFYsYG2nZzpfm7bKoS1E+dHnuEtKbsbzROGebJS4Pe26uFRWmOHIru80KqqczZaH2847
iiQp4ZUDYzftjybikZCL6lSU1WJ5ZNfqWllrTnueYnI3qiVR2nY+08GYOJ8M904hNbckFDfM4TLI
YjlSGDqFaDcXz3J+jgt5Pdufim80tWJ2Njt0JdxSimozfJjdTk7CJM95GbOllXP50T6emrLeSIeQ
3AEA4FlCcD/q2pXytkEgdFDIy4MGRk9oej7nccZ4ceNxx8r8ME+uYXm5uNmc6ePiYp4xo+nyUKQ1
yRY2eN9+bdFMWCzm4r0pJjmvGd0xgNk1NN56Muw1I8nhVXTqlZYxObiRsa3lSiPNpzSXXRG3Bms7
PBPzsqTz8eJWpm6Ui2p6Yma/gEoHh0c6T3Osvm0765W6Tj27IeHbNso+TzYboj2BibjkY6jRInWU
XLka2ffmV4YbGp4/GeE8nagwHKv1erXVpTxPLa92N1a3X6f6E7n84sTmKTRzOe+iRg4Oie65wkZ0
615rZ2AmHdhjBQ4PF8sk19Ts1gdGr2pV/cDg7uVzRXGyP9VkxDoLh8tAOobquhHCr2cBAMAzhDHu
R1y3oVZGm5ddkWR0tF3P6Y8mwy7q8fwwsZ0OxpPhkXZqhyec5P0jE5lVtdrZb5ixn09Ht8Il4+N8
24cZBZPpqG9oinBgdIpOp7sZ07rVbbuU4fgwuy1vuQOREDv8ghXu9h2kzvKZkdskPaFIaLQQeqdj
Pulo7IN0q8qO8yTNj54nu+16cnq19t31MWF4KQ6WiwRGTx19aNd+f93GHW10sA8Tjse33ffp5pJJ
brQUjcqO7TDalTV5LsGfO3PqVNDvZbf4ItnRy9xOvdE54Mi4IplMeCjbO0PbThBKb3eOcL8XAAC8
ENDifrQZer21rb3dFwpsD+kOV4BjaaVz9O5PZQOh7ZGYcrJcgF2pDW2W3qy2TGrPFk82EPYOJVAH
TTPbLjvYUMg7NLeDYbZPYeqDnWN0Go3RiLvzIYy7adnhbs/nH7pC4cBovGTcLhLch7OcYT6rI0Q2
qj66UfQulzeU08uFdux6ctrs2Q3g5Sa8o+GfcVlbNdyRoOtPcav0ZmNbXwrL7TyFyAkf9FIjo85b
VnfG5tVdt7qanRVKtcOWTG9bG7FfxwO5kBv9sTHa6dq2f82DFgIAAPA9Ibg/D9sesr4fU9/21A6a
cdE7soGDZtwkqR694M54mJ1N+7tEHt3Yp+yMyzm6EIYe/Zt27baaPZh6+8maiPcPdy7WvaMI24pp
Us8suJON2rZsK2DvLCvtZJidc1J7od0+1/atouln2FljmJ1tlwE7S2y/ynicoye8TvSvq4x6Ic0L
6uM0f5sHdYUw7I7dSbvpI/mZAwCAFxiC+xFnPqtoYO5cLkkvT3tdT2V5tHM0K9Lbx/nQju1h8lns
s/3D3fZCUruUc+zQu6T0I79NbS0nb0/tjDcSnQlzXp/b6j8wmmtiplh7nIXSNFrSAQDg+UNwP+IY
ZlvLotnukJbFbQ2/ht553Oe472z8tQasUE+ZXm8PDWAYrLq7fTAwzTi+Vx58nFZgq3NidJcy/igf
Zg9agtPD+R6zkD9cxt25UXqno+8c2WN2dX3nnNR+ftDA6qBdzLbzfUeJ7Vf15rZuE4awi9qtKtvu
5vbGCqWRJwIZTPWpNJYjywMAwA8Mwf1oczA+lqWoodv1zIZa7cQCIwPCjVZVa+wfQ2hmR7AjkZoa
Gr/c3n7P5tNACtbqTrhHhklb99uOJivG42N/sJDrcHkDLmpjuASecDLzhA9hfOqeLE2SjfKNbpRZ
1+r69odsdhvajl0fcB2lNnTG4yXn+8jgdVLkRGB0Q4xOdWPb8+rJDmB6b7W23cLg5aZDo8PS9Gal
hSEuAAAwhvBUmSPO6Q2HRu9F1bVCuTYy8L1bUwoHPMjdQW+/XdN6AHd9a+xHW8tJpafe4E4iWLkw
+tOoRlMtKKOhiw6Et93490w5A2FuZJfqSq6wsd8PgBrNO6ur2tP/4dMdHQVP/mASp3Xz5MgrHUUu
jf6sKdn1Ox4ZSU4v9ig1HDu9E5x35BVdLWw7hayTNbftkZFebqK/HTtGNOnbRvEbdaWoPvVLVAAA
gB8AWtyfh/1+OZWyBmVM8JtPwHOHomG2NJypzQ0xkaYkMWH9TFO3eUfOpFcOfIg7aVllqeFHeJO4
KiQyeob30p2GphSKSuOZNEK2SukYJS4L0YDbYbSrZXFWKG97Tg7ZQu8PGR7dXDwZLA8/+L62EuN1
cTljFXJrum6zoqnrCqE2TE5Uopz7KReTcbtpani/1wq5cjg7WozDcXNJ3l9eGcrl1nmS7IpietLn
tJ6NWBJns+WdjxYNHKXcTk7+4EycK2aHc3ktn0yY0mVhOuC0RsKsiXOZ4rZHRnLJeLDXreNgXO7R
x950lGKpEu4/0L5byWUSWRXPbQQAgLGE4P5c7PfLqYTX5PjNkOgOxeNcWRxpYeyoYpwTqcfgYDnO
T22MtLeajXI2XaaeNbNWykRKez5ukY0mIr4fNjw6Q3wmthbPD6fcWjETKWYYr99rd02Yeqs2POTi
mQwncbi8XhelDV/HtMqZSHlzXzERWclPH+5nSZ2hZCZWThaHl9bRVpLhPc80JpzJRJ7ib54+HY4A
n0ms8sOXIOQapJiOFNN7zEEH08LWU/xd1vPzFWUompuaGOVWrZ9dtZ4EijEyAAAwvjBU5uhzhhKi
GGH3mYL2R6JB5oCl+OPJyL6/0uQKBh/3V5wO5I3w3H4LpYOJZeFwD8Z8qtwTmctZbucu0xu1DVut
8UMMpnCGpiNe6mlxTwrLqeBhLzHYqCjyvqPV3N7j5NLL2TBzyKldYeFyYvg3ojyRdGzHXiAHtlbr
p3YmGI36x/2BPwAA8FJCcB8HDt+MXJT53cMGCS7FfDbiiz4NagAAEABJREFUPiiJODwzopTYI9e5
uESudHna97TjDBNKykWJ3z2ckpKX8ovcDx/bLaSBuqAUUmH2MBPTLBf2Mc8g5Dq5zGUheNiMeojF
zRfLcuzABbIRoVSWpo/I/bg7OQPJnJJLcQddSLq4VK6cS24b7eMMkauyvS5S2Ui2mE9zTgoAAGD8
YKjMmHD4ppdLvrCcK29Uq9VaS6ddXn+Am+Tj/HTATbXXDrMQ98RiUQlJWamkNuyhBAzrD4TCfDwe
5TwOo56jngEmMLOshKKlQqmsVqqNfskDoUg8yXPPNTo6PBPzxf9OV9dJ2dZUbaM1MvKZdrFeXyAU
DIcnw+HQMysoaV4uKaFyeV2r1HpHlvpenIHpy3+OpLVyoVBSVK0xvDiatbaGj8cmA0c+uDo8k/Ol
cLKi2AdHrY10gLj84fA0OfUjod1vBnAE4nLZV5KlXFkbnOneQCAc4Wd4su1GvUoBAACMoR89evSI
grHXXktE0spQuHmMH2d9eoyqHI2Iw4OTg4JSSh+x2x8BAAAAxhJa3AEAAAAAxgCCOwAAAADAGEBw
BwAAAAAYAwjuAAAAAABjAMEdAAAAAGAMILgDAAAAAIwBPA4SAAAAAGAMoMUdAAAAAGAMILgDAAAA
AIwBBHcAAAAAgDGA4A4AAAAAMAYQ3AEAAAAAxgCCOwAAAADAGEBwBwAAAAAYAwjuAAAAAABjAMEd
AAAAAGAMILgDAAAAAIwBBHcAAAAAgDGA4A4AAAAAMAYQ3AEAAAAAxgCCOwAAAADAGEBwBwAAAAAY
AwjuAAAAAABjAMEdAAAAAGAMILgDAAAAAIwBBHcAAAAAgDGA4A4AAAAAMAYQ3AEAAAAAxgCCOwAA
AADAGEBwBwAAAAAYAwjuAAAAAABjAMEdAAAAAGAMILgDAAAAAIwBBHcAAAAAgDGA4A4AAAAAMAYQ
3AEAAAAAxgCCOwAAAADAGEBwBwAAAAAYAwjuAAAAAABjAMEdAAAAAGAMILgDAAAAAIwBBHcAAAAA
gDGA4A4AAAAAMAYQ3AEAAAAAxgCCOwAAAADAGEBwBwAAAAAYAwjuAAAAAABjAMH9uehqC1E+3yD/
8qeU8nzAQV6qrhXXql3KGZiMTYecFLzojKZWlKRVrdpo6SbtYr2+QMAfCk3yPOd2WO/X14urlTbl
9E3w0d5Lh9LWVkt36l3KHZqJTfoOPRsAHBKpwHk+X7P/TXNZpZA87Adt93q+e2cuEi+2KMobK5Uv
c6j+AWBvCO5HhNGplKQV1SRfA55IJORE3nqxGc11IZYsNQZ/m51WjfynKVWa66d0vVqWV8odcnFH
WS8desmtSk5cIZnCFQlEEdwBnrpubU2tDf4wK2tKI+YLHOqThnoeAL4vBHeAH57RKMtlO7Wz4UQy
yrGMqbeqFW2jYqK1DeBIa1fW1MbWn2ZtXW0kAoHvEcKdoXS+NK1TFMP6UQEAwL7+iYLnzqjKU76w
QJphCFMTwj6WCM6ut+1321pulj8T9Fsv+oPnYgurpKe1r1tZOsfaU6dWK3fIdKf8/lN8Sr7TNMh8
hbnYGb/XGzyXkLW2QcGRYerNjn24/dFMJjkzOTk5PZOcv5wv/WcxbfWfN1dj/lDaam4naitR+4zw
x1ab1iHPpaZOedk+f/DMVGJwSpAe/DO+qNhrDOwo6ZA9yZkFrWvUc7w9j5cv1O1TYfMVa7H2K936
ndxc7Nwp60zzksXGZhdka6wOAGxpV8pqy/oHE+S8NPn/5sbaWq27bZqC/VGyPmH+U1OJudydZnfv
er5bkRO8JSVvLchaBn/G/jiSzyNZyNJ6fVCLG/XC4PMsr68ukO8Hr7Uifm6t3qUA4IWGFvejzaiv
pvmM0gtwDEPrnZqaz2iVerE4PzISsqNk+bJufyVQWlnUqipHaVq/WaimiAnKpeRnPBQcCbTL56Gp
lknViguCyQV81uh2LuA5uNHO0OuqukHmZFiW0VstvdPYUBobWsMs5+Iu6okZzTWB718qMKyXMVsb
Klls3ROOhtzo0Afo28ztbDiZ4UoJQdWpmrpWS4f6NTKptDOxTLk1mEFvbSjFDhOJJA+/kl2G0m0o
K0ltQyjm0sO3QJmamNQG/25pxXSK8ZTmcZMUwAsMLe5HgCOQ/nNdFcNW4w1Fc6JabxEby5PuZlnM
2qndn8hp9VqtqkpR1mrhWZmTtNGWFZMOZ0uqIvNe+8+GpplRsayW7RnIl4daUutodD8qHL5oonek
9I1yfkUU0vEI5/OfiS2t263fnplirSJHe0HcnyrbZ0StSK68HAzpVVcq9Vbtv//7v2t1rZAKWueN
rhYKta6TW/zf9bLgt2dzReSKNVvrfy8OXePRNL1riciXftU601xRuVL77//93xuNVlUt5zIci9QO
sKmplTT78pblolyQi4QY64+auj5oKieVtthL7S4uJZe1alUr58Rk2M3sWc/vWElblbK91M6SWlyr
qLlU0FqPrkliqTpaj7ORbEGtkq+GSK8kyvbWfwB4sSC4H2FGUytruv3Pjiql+KkpfjZX6bW+N7RK
a7j+poPJTIzzBUj7KDt4Ic2HfKEwz9kvmO16b3AGHAnuyctlRYqFvczWa3pDXclkitV9L7CcviBr
asWFuZTVuZ4SlVbvsLYaTZ06lF2TO+kDcFtvdBRZmFuSc6vrWofxTkwE0HYHMGDXyYPcTrqiWFLh
2p/ghrJW6Y5MwESy0vx0yON0ekKT8eT0Y3yStgbjhDMCH/K4fZPp+d6FvqmtqY3hCsIfTccmfE4n
Gwj12mw6rcNWBAAwljBU5ijTO91+Fdxp1Drb3mu2TSqw+SfjZhm7adTB9HIZ42Fd1gu0o5/TTBMN
7keLMzBzuThz2WjXNyrqejGXt76sdW11rRYLhPZq525rS7HYSm23azCTIkf4EO3jm/MOnxAOHy8I
2qyoNGpKsab0X2VIN46cRHgHsBitQVsK43HppFuTfIZY0jBSIxfOallrT0wym5U2G/I84dA1w9T7
ox5drKdXrfcH1zXIy3pbH/r0005P/9Kftqt6k1T0dlWPjjKAFxWC+1HGuJykUtbtwRK7j1vc6hOl
tzekDv5EXD+KDKNLOXoPg3O4fdykjwswrUhGIQdb17um/b27S8u40VTlop3aWV5ayURCHqqyxEdX
akPT7D4Uhmbowdd67wWzs60LxhlK5v93rF2tVesVpbSqqORaUVdzhRqPB0sDUHZuL/X7QHVtJc2v
DL9JknulPRnerLRblWaHCj3JbUUOmuk3v1it5wZn1RPk49rsfVwZNzP8EacpAHi5YKjMEeFgXIzd
cmK2q4OeTocrELafWkDVimKx/1yYbrOyXliYnS1UkcjHl1GTYtwZPrUgr67f0Yj1nCSrvePu8rh7
o2CdvTPC+vbuDA62qfeCN+0JhPwep/VkOqU2umyacdrz6e1Wa/PCjpxfbO/8qqvWICujruSU1nCJ
mnfkpYKmM4HQxHTycm4lw9mlMDttjLACoKyHuJJsvvenoUNSfXOr0taVbGZprdIm1+hNbbWwZj/4
abd6ficmEA70PsOqJJYqzXZ9XV7q36nqDYVw2wnASw3B/ahgfCGfXd83ivHQ4Nl/AX4xE7b6W3VN
5EOB4Ck/G+CiSSFfqjZN5KmxZnYaWjkvZpJx6zFwyWypYR9Qbywd7T0R2slyPruvvVNOc9aT46bk
KsVykZD9BDotGw2fO3cmEs83RpdLkkOwd1fDhhgN2E8KtZ4r6gxNR+wxsB0lE/axvvDgWUUDem19
RbBOsjPnpqbOhSOCZpVnM0IAvORIbl/r5XY2Vujd922ra/37QjtaWbMrbSHc++CSVvloyOcLcHxG
VnsXwLvV8zuaYByeiCBE7E9xqyxEuVA4ubJhxXw6mMimg+j/AnipIbgfFQ5fTJQSvRtJtzhD6aJS
FmOcn2Vos9PSKZoNhvmUKMx4UX2PL4d3RpCEWJTzu/pd3YzLGwzHxFIpOznoXfdEsmIq4h3pC3cE
YpIsRIMsTemtWoeJiHIqOLpscs5cFvng9vG1Ti6zQpr5e+3uLi4h5YTg0KIdrtBklAsGvYze2Nio
tUzGy8WyubIcx4+vAli9ZGtrG72L68h0aOhJMA5PONpL6rpWVluGM5S0K+2wVWn3JmH8HNcbi757
Pb+DMxDPl62K39v7wNIuNhhJ5ZTS4gQezgrwkvvRo0ePKAAAAAAAONpwcyoAAAAAwBhAcAcAAAAA
GAMI7gAAAAAAYwDBHQAAAABgDCC4AwAAAACMAQR3AAAAAIAxgOAOAAAAADAGENwBAAAAAMYAgjsA
AAAAwBhAcAcAAAAAGAMI7gAAAAAAYwDBHQAAAABgDCC4AwAAAACMAQR3AAAAAIAxgOD+DF26dIkC
AAAAeJlcuXKFgmfjR48ePaIAAAAAAOBoQ4s7AAAAAMAYQHAHAAAAABgDCO4AAAAAAGMAwR0AAAAA
YAwguAMAAAAAjAEEdwAAAACAMYDgDgAAAAAwBhDcAQAAAADGAII7AAAAAMAYQHAHAAAAABgDCO4A
AAAAAGMAwR0AAAAAYAz8EwXPj9GurslzqdjUKT/Lst7gmanYrLxe71JPT1srzPWXT/hjq00KjhCj
uZogB8c7JVefymFvryWC1sIMe+HVpXPeU6n19iHmW08FveeWKsYhFgvwkupWyCfKyxfqz/aDcIiP
W7d+J7eQ4s+d8lr1+qkzU4m5QuUQH/QDGe07coo/E7S+L84saE/zy+iFZVTlKW8wsfY09v925Btc
LqzXUfPCELS4PzftO0uJ9MqGvvmC2WlsqI0NrcOoubjHQT0FXU2eE4oN65+0y+tlPX4XTcHRYbTU
smadAhtra41YIOSkvifa7Q1xLpahAODF1NbkdErUdH80MZOJsbTZ0JR1pSikTFd5edJNfR/dmixK
Kh3NyNmA2836v3eNBN+L0VrPSUrIH5n0PZVIAC8EBPfnw6gXMoPUzvijsXgk5KL0VquirVeop5et
9WajY/8jKJRL6cATf/INw3A4UG88dUbDyu0uLsxUVGWtlg5x3/d70snN5zkKAF5QpEV8TtSoiKTI
M4MwNz2TzjY1pcp87+8Os9nqUN5kMjYdQIUPcDRhqMxz0VQkSbVTOxuVyuWV+fj05OT0TDJ9Of/n
shwdNLcb9fWlxNSpoJftdYfyw72h3Ttzp+zxL2dmV9fk1JTVZ+oNnkvIWtvqVjOquSkvl+mthdoQ
Iz4y6TnZHgvRra8tJM6d8lvL9fpPTaXkO83Nrjirm9Ze7rmF1dUF0mfqZb1RqWZ1mRpN0os6dWZQ
nnOJpaEuvAPKQ21ukr2I3tigc/zs0mpl0BtrtLXcLN97j/UHz8UWVqsvdE8tye1rFcobTaXjIbqh
rPYOrlHP8X4/nxvuKLf7Yv29LnprF86l7ANjH72Ro7BPJzs5esOd67vu3u7GKjkzrEN+amp2v73f
ra7NxXpnApk0VaigSx1eckaTVNfn+sMeRyq+/lCK3Kqcst+33nVSYzsAABAASURBVM5pQwMrDKv/
1fo4+c/ws/KdhrnPStRiqcGEM0J0tAnW4eGmJwPO4aL0P56kKFv1e1dbOOM9NVtYXYrZ71sf9ELv
g240V2P+UFrpmJtfF3Y9sud22TP4+aVVq7onbw8qqCffD/ZXTP+riRQ8NpfbLDn5duivxhpUGlta
b+45eoRUTkv9Sa36cS7Xn7a37alcYa5fewbPpXIjNdc+1VrXGtaamDpjFy14hk/J2l4lMJprc+e8
/nNzvfXuXfLeAMW5Qr9A1ljFkXq0q82Fo/mG2SrFQ73v1jmtu//xhZcCgvvz0NTKaq8l3B9Pbqt/
qUHTdrcix6PJFWWj1bGrcb3V0IpClJ/dXmM1Spm0WN5omdZom5oipoTyfgPZ29oCH0nnlVpLN2mG
NvXWRlmM8+nV7cPoasVMJq81yNrNQXkicbIi8grNMKQ8NWUlGY3ntse7vcvT1Zb4SNJehHU9Qd7V
SvlSpWPXbvXVdITPljTrPYah9U5NzWeisaUXd5Rlt7a2tkF5I9OhYDjKMS21ZCd3BxuOhqjKmtow
hqes0SE+zDrsIVXVDh2MC1JOEngy5YrVb37wXiJHutqi/TMZKSeLMc5ZL2YS2eHx7yY54rMFPZTM
SmIs0ClnYsLarl8I3UouyadLdU9UkGRJ4ChViCVzL/ZFFsB+rPqLVNcVZzgtybIQdVbFWGzkY9lR
5Vw1IOTVilZMe6ribHZts16UYmRWksYlMRNhtGwq2/9+2EmvqhWdDkQ4du8G8ea6wCdXqu7exzPs
rIjJWPbO1ifdbJXlQieyWNIqai7qULIp0XrX4Qpn83IqSNNeXiqUSuXlqNdx4HbpWl5cp+MrSkUr
ixGW+h77wV5XXKySeUU5J6XDro5Ws75HSPYlm8SLKhWylprlfc18MibsfvNOc02IpYvNQDwrF0r5
5UzUR6o+c2jbs1IrTL5oyOqTbi0bSw+aSPav1sxmtaq7JpNZWZYyEV9XFROZ/C51HtmIDJ9RnJl8
8fKkx3Fgyc1aScrpkctlrUK+T0eHJjn96WUxylIMJ+RKlpW0NcFBxxdeeBgq8xx0O/VmryGc9Xn3
qH+NakmU7NHPTDAhLacDup2AWyQWZ6VoaHliaCQj7Y+JlzMRtiHF+HyN6mhlrRmdCST/XI2sJiNW
ozvNZZVC0rpC6FaWyDSkGnNFxLwUDzlJa0AiJm60lGy2FMrFh68iTFdYELMkGjYapovEcbs8pA7J
ywnObVYLaV5QdU2cK3Kjw3B2LY/HY1bkhZUNqwalvVHhcibqZ/SaptbdDJm3WRazivVl5U/k8sKk
h9T/mVim3NpYmZMmyovcCzjUkqRxpUb7hUm/00GRrM6o1o6anPY4fFaOF0hW7496t6ZsMFyas7ti
nFx6ZXM0zORMbCbA84XVSpqb2H90qzMQX87HB/NN8/FQMiqV1ObkjGcwiSuyXLxs7+vpCBcgx1cu
1MLz20beG1Z/kUZH5ZI0bRdoOhJg+FhO1qIr33OALcB4aquypJhhsdyvQsnnx8PzklyOB/t1qkm5
uEw2bX9I3TEhrZC+Vq057fGQNvRcqeFNFIuL/Y9e2JeMCuqu6zH0DmlJcbEss2duNypluaxzW0WJ
cp44L0ulOLdZTbOR+WzcXps7LcRUvlyutCcm3W4fxwXcDEUFAuQf1rTt9X22q7cs2p9czM7YlYSb
TC8+6X6w96E6VK+QSqpfXXU3ZLHcCqZKxV5lRJbqS/NZuVQN7xgA2m1Vqro3Oi+kB18a3MTIBK5o
VkxPeOxtl8R6NJ3LadHlCeaAas09Ob8yOVjG9ExseiGa2H5jktmu5DIpsR7IFqW43ftxmJKzkayY
7B2M7cfS6QkGXDTNsP4Qx7kPf3zhBYcW96PJGkSh2a0EXn4+M+lze0K8kAnb9xwOWmYHmHA6PRNy
O91ezueyXtCb1c4efa12WLT/pVcLC7GpqanEwmqvY1avalV9eFomIohpsmqrNvfqWr88Zn11IcFP
TcVmc73JzZpaaRkHl2dr1f7EMqmofGQKHzedjJMKySB9EFpv5R1VSpHF87O5Sq/RqaGNLv5F0a6Q
NE77p8N+h93PzXOujlrqdb96OJLjySlgD1Aie25dbTHkpX7Atsa8zMXO9R8V5IuIG3qn1dIP3Emk
y7awsDn0yscJaqfTrHe2Go1coYh38C3kYENhH73bzu9oSkVnI3x48wZqp3+SYztVFW3u8HJqVxWt
5eL48GbDh8MbnvZS5DMxqFNpxsMFBjeNOxgSvXXy4TP6beiuUNg//NHz0k86Wt1oVdZrpB9vq0me
FCXMmo2hatoV4DY/6E5XwMPorc6u9cchtovyctxm0b/PfrDnZUJRbseDGbqNda1Bh2ZmhnYRFwnQ
DXWXrwYnGwowjdJcZqGwXm3v3CgmEA5ttlS4Q+EQ06moje7B1Vq3vi7P8oNqN8DnG6QTvDn0cIm2
KiUSYpOTinK8P2bpMCVnQ5HHeSjBYY4vvOjQ4v4c0C4fadWokY98q94gHzb3zstkU2/3agTa4+s/
CMbBeFiSg3XrTd00tm5hZVzufj1ID2p7c68xkma3069pzFZtozXynt7RSeW9ddHPen3MjvJYAzVq
nW3LbOrD69ujPJurdvkC7PaKSu90+8vfsXiS+9sm9cI1JbQrJbVFh5Jhb2/LSFbnXIpKXoyShhQ7
x6et5M5xZmVVaZHOD673ddPVxESySIVj8UySZV1uWl+XhJJhmgessFvJJxJSJ8TH0zPki8ftJD0g
gtQcmo9mGOdWXHAwDENT7fb25RrW6Ue1ivFAcfQNxqcfVAaAFxL5TOhUR0lzbHrkdZrbqlPJx4ve
rMVoUjmSatGuGHWrI3P0o+dyMtSuV8F20qUq9nW627F7UchHlvYMrctatZs2282t7MwMXRfY/zJ2
/+zuv112Nc84PczT2Q/k+4cmW77zisXskqXqNSHsE0bf8Df1HRNTnmmpROdFSRaSeYHxR/h4LB6d
8DkH2+4afrIa7SaVnEnKdlC11l7PxtKKiyxNINWux00117JCebjW1WtK2aRCQnzrquUwJbc2mXoM
hzi+8MJDcH8OHKR5JUCrVgt2rZArR6SZ4QEq9hNcyCexVxuapDXCpKz3Dd26398yUvNRj/UQGtrp
IsvtWIMiZCU/vdvAhq1Pv3Nr0ZvloTlRKcR3ezJV94DybK66U6+2utPukdrK/qayVu1PlUvz3/+p
iEdeUytpLXL1lA37ssOv62W1wfsCDneIt3L8aqXNmmWt4wpHQ72DZQ+bcUVz4mJ/ZIxRrVDmwYnZ
aK2v1eiwJF6e7l0AGM0mNTqbqXeGYjrplCffWMyO71EH7WIYiuVEcdtpQLv8eAolvJRIlcyQDivS
RTlad9GMPRbSOGDeQXYdPJTA1Pf8RDM+0l5d0kjjNO/b9QGBVogjrb92C/rgfdL2oVNO9+N/PA/Y
rsedfv/9QOoVUgV1d2659dVBM8GEOL9tNCDD+ncrhcM3mc5Ppq1n3StKKZdNas3S4FvFtMcabTLb
pJKjGcdB1VpbK6kdb2xFmg/1b0Gj1retlbStSGFVyCbSdF5O9tZ2QMk3wzt1eE/1+MKYQnB/Hhy+
aCpW0PIN0uZezkTrqvU4SJa0nVbV8ppGxfPyDBsKeamNhnWr55LE9ca49x9EQ/r6rK7GJ2rddHq5
EJtvtEiriCSu+rIzpEvPaFc3VHVNbYezi3uNUXYMymNqslgMSFa9ZHTr1nxKPZTJzhz8kNnNVVO1
/Kzgvpzhg1b/nlJ1RmY4V4B0DqsbJlUrisUJawy9g+o2KxpZfMWXFOMvWIO7YeX2DsOlxMxQhW7U
C4KgrKmNWMBK7jNhtqyWyoqpdtjodGhzOtKPQb5pBnV9t6Gu10zKf/BKnbRtsLKWVq7opmt4ik5F
qbQne+eA0SKHxvTGdt4E5yJduy61Xqe8cQ5D2gEoyh2Ict6yVjXZBPe4P8HBBEgUVyqVhsH1QqHR
qWh1nWJ3ndrhCceiXqUoiWVOHm3xaWobpp/zubwB1iytq41EoFdtWkPtahSbCLgcj/u1sf92GY85
/UHrinBsuX+fz8g7Tu9k2Jsv1XRXZvpxnmbu9E3MsO7OmiLXyP7sX0pYI5OaM57eGtoVa5gSF/Y6
KWbfak23686tVgxrnzZMarScTICX8lQmQbI71cvuT1ryIaRPgDKHruMc+x9feCkguD8f7onMslCL
idbAbr1WXhHKm2/R4Rnyv85gOpuoJPMbpr6RT4bzm2+zEUGIeBxPGNwpdzgjxKqZYs1slDKRUpZ1
mf2n1jARbp9FOrl0NlWxHj3fUrLRgORyUZ3e0Bea82WowyCrzsaqabJqs1HO8uUs1Zs9y0U5d4Bf
zKgJUe3omsiHJBdLd1q99gh/Kr7VFvViMKzbFHRXOJGcHvmO8NPRgrLSvynV6Z8Os8W8KFKmNzG5
OUbS6Q2HXEUlV57x8169VhJnJXK9c3CTDbn04lipmC9VuITfbCjSXNa6DhwJ7uRyTszmqHjAaTTX
VySNicjxnb/A4vBEM5lyTIhHa3w8GvazjE5CfrnGJOTLuDkVXnzdakXTOltVEmlP9nOZTIRPpyNN
JTZDAihjtjRF2TCjonRQo4bDE0nyuZg0m2GWhSira/Jctkx6Jtk9piffHfZXQyYSVTNpPsSYzZqm
EhUzkitzPjeXTEfUDFkKSYse67EwYr7BRqV48Ak6Mt37bdfjTn9AJe4OpzNhNSOkGJ3EXKpdJ1vV
8CWlNOcMJYWYmhTIFltL9ZIvn5paVjvhrJzc3qbTvrOQXmn5I9FwwO0wmnfyuRrlnQ5sVXS6KgpL
VIK0mLQr+WxJ57JJuxbet1qzWstoYTWnRMSIq6OVsoLV7LajidvhDMSt7B7LJpJmPkf6HR6j5Lsi
Od3j0iul0rqTXAiQhvqA52keXxhPCO7PizOULij+orRSULRGv8uMfCy9AWt0s/WJdk8slhROEuVy
pWZla4b1BsJJIRMPfa9w5PBMXy4HwmS5SqXW6FijbxgvFw6HI9Oca78Z3RPzpDxFcaWgVRudjj1f
kOMmI9MR9nCx2uGZvFxWwnlJXtUavSdC0iwXDNgPSCD7o6hwBUksqNVGq9MiYZQli+ci0RnvC1Yh
GQ11taKzPL/9SJKsPhPKZ/s/xUT+ivjzKzXKPz09FJ/dE8JyVhRlPiDoFO2NZMSsJkoH3xZKLr2W
RVOUYwGRzMeGY1nRI2XrQ1PQfl6YMQsZvmZNEIxK+ez0rs1mjkA8V3ZJWbksky8+60iRw8RPh9BV
Cy8+03psanx4JHRv/OC0VHaHskuFUra8Ytde4chMjDtM3ejkMsWcU8hKUU4ggZ1LCIJT2ucjbX01
lAOkCi+J6V6LD/kERoWiwNsJ1OGbkUuMlJXEZLFj0qw/nMllExNP9mPc5Ptiz+0yHnP6A9fVL3g2
Gy/aX3heHxfujUi3NrnkE8VcWVTy1kPR/NZSw7sslXEHvHRFK4ilRkusJttNAAAQAElEQVQnX1Fh
Xiolo5shmWYjmTSzlo2vdKxRMJFsURwk6P2qNdJakZU6oiRGfGlSND+fkVJr2dJuW2Fl96KZjmVj
SYpkd+7QJd+dOyyIGVEi1TKpt72xUvky9zSPL4ylHz169IgCAAAAeGF1tYVoTOVy5csTaJyGcYYW
dwAAAACAMYDgDgAAAAAwBjBUBgAAAABgDKDFHQAAAABgDCC4AwAAAACMAQR3AAAAAIAxgOAOAABw
sEuXLlEAR8OVK1coeCkhuAMAAByApHZEJTg6cEK+tBDcAQAAAADGAII7AAAAAMAYQHAHAAAAABgD
/0TBS6h7Z+4Uazkzp3UpAAAAADj60OIOAAAAADAG0OIOT4dhGBQAAAAAPDMI7s+H0dQKC4mpU34v
y7L+U+diqbmlgta0sq9RWTpnD2MJJnJruRSZxp6En1urD0fjbn1tIXGutwCv/9RUSr7T3Hy/fUdO
nAuyfeTtc3xqab2+Z7TuVguJ3uTeqYU7bbuAd+TU1JmgtXirgInh2TdH2pyaXV1dImsiU4UFrU0B
AAAAwLOCoTLPQ/tONhYvNqx/MqzXZbZqarmmVumJKOdxbE7VUbJphWJcDPm33tKKaV6nytK0NUVb
W4jF8jXTmoxmaFNvbZTFeKUiFeUZn4MyOrV1pdaxls7SnVZHb9U08l+lJZd68w8zSWrPxASFTE6T
a4X84oS7W5GTMVHTe4tnyOJrykpS28iWcsmAc2jeVlnImCYFAAAAAM8cWtyfA6NVq1ipnQmLauW/
//d/bzRaVa1cyE576dEJ/YlCpbZRqxQSfuvPTlnObXRJg3clt2CndldELFcbtUalJATJrC0lmy1Z
7eIONjxfUqutVu2/ycKrai5mz99SckpjtNXd1KulrdRetFI7ZVRLomSldoYTSpVqrVZVxDC5etA1
ca5Y3TY/zSVkRauo5eW4j6EAAAAA4FlBi/vz4HJ5GKqm62oum637Pb5AKBTycxPO0bZwmpuJc27y
DzcXnwkWsxsmRVrNG4bfXFNq9hR6tbAQW6Ws/N0wey9oVT3uczgDfpemyAWt2mg1uwZpMrenN1vV
tkkFhlbTKmdFe112arfXZjTUNc1emllfXUis09biW3bru1lTK61EwDdUxExWmLYW6HFTAAAAAPAM
Ibg/Bw5PVMhqzWyp1lCLDbX/Kh1MFfPz3FYAphkX3cvYDppxW/mZJPOmaZrdjt6bwmzVNloji9Y7
um5QpjobS5Yau6za3H1gC8PNzAT7azb19mDxnYY13mZ49m5TH16Ai/W6HBQAAAAAPHsYKvNcOHwz
y/9ZqajlUk5MRIKsNUTG3CgVRu7v1JstvTcwpdupN3thmvHQNO109QaluCJypTWqUYr7qGpZ7qV2
f0JWKvVWq1qIsbsXhPb6XdaqVCGRWe3dfUouEnqLpzlRrW9b/n/Oh4bHuNO0g6YAAAAA4AeA4P48
tLXcUu5Oh/GFuMn4Yn5FCFvpud9cvqUmZ/N36u36naJU7I2N8XIhr8NJ/tfO4R1FEler9g8oGe2q
tirPpRbW21a7eK9VnPGEQgG3g2pqJbW1e0lYLpOXotbSWuVMQlhrGpSDDYW81numJovFSm/x3bq2
lptLza3W8dBHAAAAgOcCQ2WeB7OpFrPZlazL62cZqtOo9YaQ+8OBkYEntKmJ8bC4+bcrmkkGrQbv
cEaIVTPFmtkoZSKlLOsyWx07qzMRzqQc3gnOv1KrUbqSjpyRWapVa+h7lsXpnRHzph4T1E6jlI7R
dDE7mc6mKumVDb2lZKMByeWiOr3BOTTny1AAAAAA8Dygxf15YHyRSDgY9DNma2ODpHaa5aKCrOQT
I+NQXOGsnI32njTDsFxs61mODs/05bKSS0WCXhdN6VZqZ7xcNCGIaY603Tu5zLKciliDYPRGTffw
khTz7lMcZyAurwhBa4BMo5hOiHeoifmSUshGOa+LIf0AJLUz3mAkJoiZCIsh7QAAAADPxY8ePXpE
wVFiVJai0ZWa1cAuKyvTeFoLAMBzd+nSpStXrlAARwNOyJcWhsoAAAAAAIwBBHcAAAAAgDGA4H7k
OELz/9mapwAAAAAAhiC4AwAAAACMAQR3AAAAAIAxgOAOAAAAADAGENwBAAAAAMYAgjsAAAAAwBhA
cAcAAAAAGAMI7gAAAAAAYwDBHQAAAABgDCC4AwAAAACMAQR3AAAAAIAxgOAOAAAAADAGENwBAAAA
AMYAgjsAAAAAwBhAcAcAAAAAGAM/evToEQUAAAD7unTpEgVwNFy5coWClxJa3AEAAA72+uuv/+Mf
//j73/9OHWE/+9nPfvzjH8fjcQoAXkRocQcAADhAoVD453/+53feeYc68m7duvU///M/yO4AL6R/
ogAAAGBfpK19LFI7QcpJSksBwIsIQ2UAAAAOcMRHyGwzXqUFgMNDcAcAAAAAGAMI7gAAAAAAYwDB
HQAAAABgDCC4AwAAAACMAQR3AAAAAIAxgOAOAAAAADAGENwBAAAAAMYAfoAJAADg++p+vfjWK6+8
+9l9g3qWHn75wWuvnF2+92zXAgBHFVrcAQAAAADGAII7AAAAAMAYwFAZAACAZ8p4cHPxg7d+/tOf
/OQnr7z21gfLdx8OhroY95bPvvLaB9euLyfs9623r919ODTrw1uLH/zitVd+8tNfvJtavvWdSQHA
SwzBHQAA4Nkx7l9PnI1d/cb5zidyLrdwwXnv3y9eXLzb3ZqiffvqtW9fX/jj//l//58vPjl+bzE1
/+WD3jvdu1cuWrO+fUmWLp13/m0+IdxuUwDw0sJQGQAAgGfm4e2rl/9ivP2Hr4ofveogf793/vTx
qXcvX/3ywzd6L1Am5T49tzT7zjHy72MfLnxy8+yVG3cfvPf+cePBrWvXvzvx2y++EE877VnfPhE7
+7vbFAC8rNDiDgAA8Kw8vHfzbtN9+jfv9EI64Tjx9oVXqXu37w3a3Gnm+C9POgfvOo8fd3YffGcN
puneu/1N1/3m21tvHn/z7VdpmgKAlxVa3AEAAJ4Vs9vtUu2/JP/tJ8mR1+lfdrsGdcz+t8PppAex
nnJQDgdlGqZpz0tRTvLm5lwOp9vppLoUALykENwBAACeFZoEb8r95u+lT950jr5+4jgJ68YB89L9
DN/P9YbRNfAId4CXGII7AADAs3Ls5IXTJ27c/dY4/vH5447Hm9d58vRJ581vvr5vnH7TntVof/O3
73TqOAUALykEdwAAgKej++03d++2t/I5aVc/eXru0vl3k8m3Hvzlo9/8+pfHneaDv938y9fmBUl+
/9X9k7zj+PmP37928Uo67ZQX3jvevXs1I9xoUwjuAC8vBHcAAICnwTS//TzNfz70Cv3LP/zXFx+9
J3917I35xc+vz9+4alK05423z//mw9OHaX93nr70RZHJzF8592+/oyjPL3+78HvnlSsY4w7w0vrR
o0ePKAAAANjbpUuXBEGgxoQoileuXKEA4IWDFncAAAAAgDGA4A4AAAAAMAYQ3AEAAAAAxgCCOwAA
AADAGEBwBwAAAAAYAwjuAAAAAABjAMEdAAAAAGAMILgDAAAAAIwBBHcAAAAAgDGA4A4AAHCAn/3s
Z9T4GK/SAsDh/RMFAAAA+/rxj39869YtahyQcpLSUgDwIvrRo0ePKAAAANhXoVD4xz/+8fe//506
wkhbO0nt8XicAoAXEYI7AAAAAMAYwBh3AAAAAIAxgOAOAAAAADAGENwBAAAAAMYAgjsAAAAAwBhA
cAcAAAAAGAMI7gAAAAAAYwDBHQAAAABgDCC4P0OXLl2iAAAAAF4mV65coeDZwA8wAQAAAACMAbS4
AwAAAACMAQR3AAAAAIAxgOAOAAAAADAGENwBAAAAAMYAgjsAAAAAwBhAcAcAAAAAGAMI7gAAAAAA
YwDBHQAA4GCFQuEf//jH3//+dwrgiPnZz3724x//OB6PU/Ciww8wAQAAHICk9n/+539+5513KIAj
6datW//zP/+D7P7C+ycKAAAA9kXa2pHa4Sgj5yc5Syl40WGoDAAAwAEwQgaOPpylLwMEdwAAAACA
MYChMs9FV1s4w27x+oOnzpzjUwsFrd6lXnTd6pq8RMhrlRd/Y/fSrSyd83r5Qt2gnqa2VpAL6/ss
1GjeyckFrfmkq23fmT01cubaJ+7SWvWHPpRtchbNJqZO+UkZzkwl5uT1kSIYVXnKG0ystanHZtTX
l+wFk82bylWf7gF6TN3Kqpwb2blGlZw4p1LrvQ1rryWC3il510KSQ11Ymo2d621J8FxsYXX7UerW
13NzZFu95O3EXG54F1r7dy7Bnwl67aM8lZLv7DhpyOyytQIv6z11LkYOwb6nVbuyZk0dtJaWWCgM
LW7bSTVwZk7b+6wymtrqUoo/4yeHn5yAq6OntNFcX4hZZbe2e07+4U9PAIBnBcH9KDD1TqtR08p5
gQ+H+aU77ecaFp4xo1MpSSuEVKx2XuQNfQ6M1npOkpWmvucUer2ck3LrLZP6HphgSi6USqVCThTi
YU9bWUlH+bn15g91NI3qaioaSedazGRGzMlicpKpyslIdHbtKRShrcnZlYojIuTIJl6Oeh3U80M+
KwVJKlWHjyftC3ChgJs+cN6WmpfVDhtOZuWcLESc1Xwmyi/c2byUMZprQiyZVcxQWpIyYVPNJhPC
YA92qwV5tUH7ZzIS2cGxkKmI8Wh6+Dqzqy3FoslcyzVNJpHS02ynUtn7tDLqhUwsLVbosCCJ6YBe
EuKx7KAs7lB6pTSkIPJeimJDYa9zj8V1K/lULJOvszNZSYyz9XwmlsoP2gGMaiEdTRabvmhWljIc
pYrpWPppXyIDADwnGCrznLFRUeRdeqtRUdeKSs2kOtpKMkEVi/OckwI4imh3gJvg3ORfHPm/eCK+
RkJZMZPxeQrJwDMPuka1mM2WqahUkmZ8/bVN8+FQOiYIQiiQi/u+TxEMvdXSmQCf5Cc9zzOz78Xh
m1kuzhxmQjYilnmPu78RkxEukOSFUl5NcjPWlnVrBVlpeWMFaXGCHMppzqfzfFEuJMPzISflDKXz
ZY+nXwdNToc5ho8Xc4WN6KJdMXUr8lKxxUkleXAMpvd7kkVby8mqGRSWpTRZOBUJMXo0XVopxzn7
hHH6Qpxvc2KjWllqUV4+GnLvtThVzm3QYXFFtA92JEB3ooIsK9H8jIe8mZMVkxPzsv3mdCTkiZMI
L2uR5Qk3BQAw5tDi/pwxbIibmJyOpxfzpVKWY6zXzI1STtlsO2xXCnP8Gbu/m3T8kl7mpW1DIbrV
tYXEuVNWn7bdZT3b7xkm3ej2TOy5QVf65iv9znWjnuO99nL5nKYV5mJn/Fan+NJavWt0q6tkqUEv
6YmOLY00ppIueDk1Zfehs6z/1LmRAnXvzPV6vc/Mrq6RyU557W76hKxZ3QjWAAZfWFDthjlTE8I+
a9Lg7PoTjGh4kZFDOhc70z+iU6nC5pii/giQ3KqcsodAWLs2p/X2XlebC0fzs/qhrgAAEABJREFU
DbNViod2H2rQXktF4qWW2cjzgf6ZUbGPXLe+ttAbFcFaJ8BgiYfk8E0LQtSla4XVjcEKu5XCbG+4
Ces/w89tDdIwmqsxv59fWrVODvK+3x4u1NasUR29GfzBc/xsobJXEUguy2lUOJOJDgd0R4DPpDlT
JdFyt1ERpHV57pzXf87qFrBGCy2keGuEh33+bg0hsfZuICxouq5mOJ/1sbDbaQ0SO1P9sTPBM7GF
tc3TvXc4YrnVpYR9OIKJteb2NVfkc/5gaugM796ZPeU9s9A7NvscUPJWNJzdMK3C2EcrmFprbxsq
s+9hcW+mdvtPL2nBpvV2vdMrV6ey0aC84elBOnb7p8N+qqFVWvbWOTdTe+/dQDjEUnqr3WtTJ5VS
ucZGk5HDXSR1W1qlQ/snw/7eMh0eLhpmzapW7ewycW1trWYOlWyHdlWtdpgQWURv7Q42HCWXAlWt
3h6sKxDh+m+SDefCfrpVURsYLwMALwAE96PDGYqmIqz9z05FtbvHjeb6LB8VilqjZfeWm53WhrKS
jMblQZRrrs/xkXReqbU61leq2aqpJblc1x9v1WZFSvBCUW3oemujvJKOJZN8NEOW2jFNvaGupDPF
fvYnLW3xSFwsbzQ6Js0w5Ku8Zhcot30UaaOUSZPJrM5zs1NTxJRQblJwCN1KLsmnS3VPVJBkSSBd
/UIsObx/O6S9sRoQ8mpFK6Y9VXE2a8dFpz+9LEZZiuGEnD3iYCXtH+21cYczkhBmKDaStacoL0f9
DnL5tprh08W2NbJAltJkfdlYYunx7j8gQYxzUa1ab/ATiZzJmKCYoZgky2Is0C2RFQyPVdC1vLhO
x1eUilYWI6zD0NvVhumdTFsDX9IRd7ssJDKruw5uaFcVrcUM5bKBXj5rqOu17SW3NzCjODP54mXS
jG7qrWprcxAI56wXM4msHYQdXv5yUYp5aTqYsMcCWWXramIsltUoLk02Jhv1NIvpWGZ4TE5HlaQN
NmMdjlI27KIe3+4H1OGNXpZ4LzUoTCmfCX+fFmO9XmmZLk/A5ej9VW2atC/Ebp4iTjbkc5mtyq4D
rYxOo96hXV6PPUSn21C0Du2kKyJ/xt9rL9jRnjC66gZZtc+/dcwYX8jDkDK0dpxmJLcrNco/M+3f
q8vRLgvl8vtcg8U5GLJsqlOvWaefaf83MpTI+qNVq+sYLQMA4w/B/ShhfJzPbnOn9E6HfMu0VSlb
alh/s1GxrFXUXCpova9rkliyknT7jpwt1uxZgzGppFWrmlKQMhEPM7zYA4fDWt90AaGgqrmE3564
pakdTiipihzz229rq2rDbjEviZJGvthJOCxVqrVaVRFJECQFEueK2+6Qo/0xqVypVkoJexEdraw1
qUD6z3VVDNsroTlRrbeIjeVJdGEPGE1FkjQ6KpVyi8mZ6ZnkcjGfYCs5ebMV3KRcXCabngi43R4u
JqRDur1rrUbSYMBF0wzrD3GWgGd79HH6An4XQ9NswJ4gFPA4SEN9TlapqFTML8anp2fS1vq8tZKk
PNagYMbDuiiz29ZJZmoqcqHiismllfmZ6en4/EpR5hlNltWtVmLan1zMzoQ8bo/PR5qFSZv95fzK
Yjo+bXU+XS6W5ChdKamtnSWwR7KQfiqW3tHU62BYN201Cg8HT7NNLoNiQiWQLebS9ugeyhmIL+eX
rZ1LVja/XCBp21RLqrUHHe5AMORz07QzEJog+8fnpupludTwp/LF5bS1MYu5vBg2FTm32bBvUkwo
LQqT1uHweZxPMLxmrwPq8PhDAWZQGKs4Tz56ziBVhazoQT4d9vRWapJDxTDMUOVg/2W/vmPuaknK
1ZhIMt5L03q7o5u6tiIqFJchV5eZEKWRy/fkHgPJDVPXTZp2DRXfQdsr07vbV9aurKkN2mr933Nj
TZO0+9Nu91AlRzNuJ229Tt5gAx7GrGtbjRedukbaD0xDf8zmDACAowjB/agyre+wstqy/s2EMwJP
Uo5vMj1v3bZlJWny9Wa0KyXFnoDmMsvZGc7jdHoCEzPJmdDjfsN7+UxswufjpsPe/gvRdIzzBcIz
YTt2U50qaYgzGuqa1hvmUl9dSPBTU7HZXO/OObOmVkZyFhNOp2dCbqfby/nsVki9We18r1siXw4d
TanobIQPb46wdvonObZTVQdt7jTj4QKD0ELSKsvozfoT3+bbbahagw6EQx5qa30hl15VdhvGsA/n
4AKxXSenAhOKBDZPQncoEmLIxeBWr4GX40aDWbdiPyOkN/6KDSXLLbJRze95vpjkyjeREJucVJTj
W8Ux2lphITHVG1zG+jhB7XTIHty1i6FTsQ5HaHLzNkkHy0V8dEO7Mxh4QZOdt6P5/7E83QO6C9Jx
l40l8x0uezn92FUD1a1alz6qixezM4OTsndgvImV3GXr6jK9UpSiLl1dVRp2sY0heyx1j9YEq85r
MNxMZOimYOMQi9tansMTjkXYTjmbzWn1drtO2jZEtWNNQB+iBeN76X69+NZPtvz052+9m1q+ef9w
fVfde19eW77+9UPqh7KttK/89LWfv3X2A+GHLMIP4eHdz5Y/u3kfnS3wAsHNqUeJvtlOxLhYhrLa
qey/XKyH6X2P0S4f6axumFajF3l3MAHrDbgOER1Mao8kRLs9LutbjbTu9b7cGLev98LWvFYPtD5o
zTQ7jdporjO7zZGmOsY1aBGjB1+YJnL7gezGSapVjAeKo28wPn0wAMBqrNw82nYeMU1r3z5ReDS7
pDGUcbmGQg0Jkr2Tzzj8MvV2nSzH47aaUTu6ToroHF6ikxS5d7barzLOkT4hayxLQqj4onw66mNZ
j9OsFrJixdzlhLFzLVXttHYWzrBHYG+dd6RQNaVsUiEhHh4ait2t5BMJqRPi4+kZktvdTrMiC1Jz
95PTsNqfyf4YynykrdhFm219M44xjIv5frexPtUDukNXk1Lpoh6RitLM1q3DpGeGdE/ow59Z+wDZ
r28hh0aIZStsKpef37q1k0xDW1dfk5tXX9a1mYt0sJH6y9uQoxGx1p+SyyqFpLWBZnP40siwV02P
nCWUdRMraasg/Q/hrSuhrpaN8MVW7w8mIqv5CE16Vsz2aM9Ks0uK7raPk3tSLJUC4oLEh7OkBN5o
IhMti6qboX+Au41p+vX3pYULx6nug3s3rl3507/H7n5X/Grl/LGDZuze/9PVK91P3rnw5rEf7qbo
QWkdRvfhgwff/O369U/Tf7l5W/5Cfv/Vo3hr9uMzHtz89MrNN06eP/+CbBAAgvtR0q2UV3oN6JQr
FA4wvd5kS6fV1A3O6oU3O4NmSMZN3h1M0GpUO70Jhg0Ss9ntpQCjU23v0Vu8ozGKzLuzniMd0r1Q
RHOiUtj16R2b383PunXrBeWgXQxDsZwobtu9tMvPUM8AydQkUnc6Q0HYtEI45XmcnNO1Rp5TbMS6
fjTtkN5pD0VCe2gFPTIuY4jR0kqaHsqIYrK/ze1uYa9rTHs4WalCVsd7RvaQ0dDUmumKcFvPEHSF
BSmsCtlEms7LyV5bs9FaX6vRYUm8PN3rYzCaTWrPK0qHFWPNtn1N2l+ZYQ1jI/H2sC3XvU/hcD42
f8ArWKO5lp3Ld+zUPrK7GF/AQ5frlVZ3uj+iqtuq1Ds0Gxq6piIXOYKosqn8todcMZ6Qjy63R8eR
9y4q7TsFVsrcoKIhF1rklPB5WVqtN1rGRL+S0puVps4EAqxzpLBqWeu4uGh46IE+Tn86X57p7zGa
8brJgfCSTjylRnolQr0JSc3W6JiusL/ffOHwcMmV/0xK7WaHdnnoRo7P095Q4EnuP3h8ztffOH3a
SonvnH/7Vfps7E+3b37z8PzByf352Cwt8d5HH358Yf6DxOeZxPET/7HwJp5rBnAkYajMc6a3Kpqm
3Vknffc8n9Xsrzs6yCcj5BuJCYR7Pei6KomlSrNdX5eXemPeKW8oxDrIBKHec2g0aTa7qjW7htGs
rBVW7TsLaTfb+6ZqbVijWMi3YkGpUd+Hgw2F+iN1ZLHYu33R6Na1tdxcam71kGOiHYwVTa2FtKtN
jDrdzmU1XXbqdWs0ybCQ7zDDp2lyZbVvLqQdVnoemsDpIoFGr5DAtPUYo7LWIjnHd9icY9TXstli
i+HiM0Gnfd+hj+lUylvPhWmSPzrW7Yh7XM1Z2Xa4pZeUoNLaY2UOTzgRZcknQioPn3DWKGxZM/3R
+MgNnEyAl/LZUF1MpHOD222dtG0wY0srV/Q995h11+PIHa9GS1UqJjN8V+e+HFZ3mdlsbe5eKx/r
h03udhcYOZ5P2NHfviMmMgqTWBZntl9lW0N+QlRDXRscpnZtTa3RoWluMEilWy1kUlKTyy5ntj+a
1uENW4OfKpXNe0vtB730U7/D7Qttsm5hoJzeSc5LWSvoT98ml2qkZT3CDZ9jZNeS05ANR7mRW16c
nsDm0gL2MH+3dW+ybg0kNIZn5CKB0XtlHG6Px+mwHkO0QY+OvvmBHDt5+iRDqkhjcLyNh3eXE2d/
/lNraMprv7i4ePNBb2jR/c/e/UXydtv8Zv5X/2KPW7n42X2jezfzi1d+Idzd6qh4+OUHr71y9to9
+w7we8tnX3nt4rXrix+8ZS3wtQ++fPDwZuK1V94Srn+WefcXP33FGqzzrvDl44wScRw/vyC+f8L8
9svP726OmOl+/VmqV+af/PQX72au3xv5pbOHd68lzv7itVesLXrrojU0yLA36OJPf3rx+oPNdRtf
L771ys9Tt+ylGg+uk7ffvXb37mfCxbdee4UsNnXt7kPDeHBrOWUVnSwq9dnXw+vp3vsyc9FezU9e
+fnZxNabvf3wwbXrywl7P5BZP7jWL7y1B899+p3Z/BP/r/Z4oF9k7u46cIlsItll9tJJWRKLg218
ePezxdTF3sb/9LW33iWF2totdwVyeFI3v765nHj35z8lpfpg8cv7XePh19eFD87+/BWyVRcXbz0w
RvbVbkffWo994DKf9UvxyluLZPvIJi9nPjhrH0ky/buJ5bsPMOIHLGhxf85aZSFeHn7BaiWUEvY3
pcMTEYRIXSDN8GSyaFkYTEMHE9k0yUgOZzSTVeuZcoPSN4oZvj+6gvQnh2dCTqd/ejqYr22YOuls
9mWpp8DJpbOpSnplQ28p2WhAcrko0vxoF4nzZQ65ECvY0eWOSTWK8VDRGg0vKbmZI/nQ7GetWyWX
bZ2tLScNiv5ANJMpx4R4tMbHo2E/y+gkKpZrTEK+fOA9vA6X10NSeKm07iTtywzr33F/Ku0iDa1F
rVBep3xO2p4inExzalbMSHRqwu0gcS1b7vh5kd/7iezkkku743ZT3XpN01RV0Rom7Y/JUsyexeGL
ZGKrsXxWkCnSzG207+Szisml0vazA43dSk2uUCkpl9PCAke3VFkQyiS3s3us3T2Ryca0JDnfm1oy
HvYyVKehrsqlDTOYWknvyJjOQFzKU5lYNpE087l0iA1xrFTMlypcwm82FGkuq5IzeHb0LU4AABAA
SURBVK+LFKc/nokq6eJc1ifM+JxGc12SNCYsprnD3k/tDkU5Jp3L5v1kl1LVsiQWayblPdS8Dsbn
dZnlckFhyaEhnS7kk0MdVvvOQiyZb3j5LEeR49R/lWb9IfukcASiiWiO7MYMneFDVLUk5xssL0R6
h90gqT0mKFRYiLg6G1p/WJx9flpJ3OGLJiK5pBhLNtM8x3SUnFwmaypE9zhpyG5MhksZcTbTTUcD
plYUyy1/Yjky/Km347fu5WcO3rVuLh4PlsVsStCTYXIVJ4vWQ+KT/RnJQcoXKpQnQPYduSzL5a07
7Veivh++hjG63bZJH3/1eK+z5+HNzFTsTw/fuPCJvHDc+PbGp9diFx8W/7xy/tjx82L+u0zi0+4F
een94w5yAX6C/O/Bj/xs37582Xhf/OP/ecPZNZ1u6i75cH57/fKN9+akv+ZPdO9eTWXSaffxL2YP
33ruPHnh7ROff3rvmwfG+WMOKxd/cPHf7x2/8JG88Lrx7V8+v5Z+94HxVfEjq5W+v0XdN37z/tIl
UoT7f7v9t7sP3j//6mHWpn9zOZF58/yHHy/9+ru/fHptPvHg3unuN903P/xEuvAdWc982vnqV+Jp
+1cDvr72wcX5b5xvf7jwCVnN7c8v/+7iB+Z//PHjk87Bfrh6zfHbhT8unXR+d0NILabm3f+Rf++4
8+QnK3/opn536/jvV+asXeA8fnJn0bp3Fy9evHr/xIWPrI0wH3xz+/bd+90LJ53WAKJv75snfv3J
bz6xNu4vf7r+u1jb8efi5jgi87ubmcR3p9/7zYJ4/m/Xr15Nxx7cdt/77tj53yycv2C9kMic+Ko3
+T5Hv7+sb69f+fT8J9JX+RNGlyKnTPfBt992j/36t+InTur+327e+PLfP3hI/ccfZ0+iJ+Slh+B+
FFhjjF0uT4CLxuNRbujZESR05MuBgiTm1Kr1REjaRb52o2khM9n/FnIEZlbKgYgkyUql0XsiJO0N
c73ebkcgsSJ3BdF6zCPF+HkhE1Iygvq9WrndE/MlhSuKKwWN9E53yBc64w1y3GRkOnLYG/Qcvpgo
NQUxr7Wol5pp1oqZ+PBY9t4QpEA8V3ZJWbksZ0vWQGDSlBjlp0OHGSnjDgtiRpQKGV7UKW+sVL68
LciSxJWV6qIkp/mWSfmFcjkdCiWt9QlSNrnSMRk2GBaK2eR+6UnfWEnHV6yrAK/f5wuRq8iJcGTo
vHVz88WSJ7sg28VgvFxUKgkzgT2/bxwBcka0RSkT8pETyhWMZSRvQVD3XL97MmsNYpbkspgp9XYc
y8UkITOz+6O/rexeNNOxbCxJkeyeXhZNUY4FSNloNhzLih4pW9+zbJ5JsVQMZJfIxrR0ssUcLy8L
04+RAklpV7JkZyTDokmx4URGiErZ6uHmJVfKy4IuFoT4ik65orKyEqEOqdvSNHKFQNVKQry09TIb
KyiXJ5ybBTPnpLyg5q3PcTS7nJ3s36Pcqat2WlfFtLo189AQOTJzXqJms8WsVqTsk6YgJPb+gSNy
3on5DjUrrWQUynoIFi9dHm3INxrKWsX0x/Z+DOTwfgmRqq2dyeZ7JwDLJWQpMTjBSPHaG6X8yor9
lyvIiytCPPRDpx3jwdc3rmYuf+O+kPvQjlrdb64u3njwxid//qI3COW986dPJKaEq9fvvT178tjJ
k284Se/KyZOnT58cdHkcuA6TYk5/Ii3Yw7et+Ge3BtOvfiguvW8v5L25hb/djt24cf+jNw+f3MlF
A+m3e/CwS9bveHDz6uffHPuw+B/SO3aZ3zv/Bn02cfXq7fMkcJItunzj4dt/6Md4ijr/3kezvY0/
1Jpe/a2c711SvPOqcW/q05vdzUVZL1y8fePr7ul3nMaDm1cu/81xIfcf8nvH7c06f9L57sVrV+9e
yPdSr0m5T88tzb5j/XGMhPubZ6/cuPvgvfePO4+/cZJc8ZK8/sbp07sPVjLuXb/82f2Tv/9i8+rm
vfc/7r/nePU96Y/v9f8gG/f+24mzqeu3H1x4dXPAvOP0Qp5cIljvn3Y+eCt945vTpT9LdknsF4Tr
d+3J9z36/YUdP78kfWxfqdhFdZxfyJ/fXPn7H10Qzn5gHcuTGMP00vvRo0ePKAAAANjbpUuXBEHY
Z4Lu14vvnrv67dArzC9//8Ufe4Gw+7Xw7rnrzj989cVHg9RnPLgeOysYl+yXHnx58Wy6+8lXf/54
M7jfzZy9ePftL/rNzpQ9VOZX6XZvGtIUPnX2Cr3wX198vJkiH95M/Crx9fkv/ir15zDuX7t49qpT
+uqPdrbcUdqpa86l/9oqUH+ezy6e/d2D86WvVt6hbqXO8rdPl/5r5Z1jQ+uIfX2+9Ffpzftkcz87
Jv+1+P7xbdexZBmxs4uUuPWW8fXi2akvTxa/spZkbfhbmYcf/fmrhTcdm+ucN8mW9VOs/cKiw15A
+/oHb6XvvUfW+M4gsXbvCmcv3j5d/Ep6h7b2w1V66a9ffNRf1UNS6Ni993oLN74WfjV1843eendh
7aFfLZqXNte8fSddv/rp9Zt3v/lu854dz4e9klhlmLpxIvdff3zv2NbxunUy/1X/coLq3sq8Fbt7
3jqA1P5Hv2vv1LdLf115ZyiUd+/f/OzqtRt37327OaaU+XXur7scyyGiKF65coWCFxpa3AEAAJ6G
4afK3L7+6edX5q+++cUCydFGlzRh69/+7v/+l9+NzvF688l/0dXpdO+49YU03A8/0Il63Md5md1m
V6ecx5wkQrbb3S7tdA6vw0H+pM1u1yBb9LBLOU+6n/BhPbRzaByfw+EgRR16xpDD6jixH/9pkD1n
Us3P+f/r89EFMCdIIXpPQSCF2ioFmdVBmcbhnstkdttdij52bLc7iIz711OxzDcnLrz/yYUTx48f
d5r3PhcWvzasG/md/W0YmZG2S+IY2Yje/Q2HOPrWsobfeXhTuJi4eez8+x9e+Jis/Bj14MZ85ks8
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
v9XSuxZsNjSKJo+vy+9Gs1ys6O5wpGtwmtYCH04W1fYf7miuNBNk7SsDuknyfGf9JvmTon2M1adP
O8jTlDMYDq4shPWHOHe22KypBsduM/cDPBdIkADw3CG4AzwvRjUnpItUTO5O7RbG53XT5Vq9aRzq
ZFm9YZWxBwLutU7p1nVpTKrZqb37Rk+HNTOlrMvcNGVlcOsh1p/KFkc6JTA043WRdO31OanSEgnO
wXYjDLVaV01nyO/sbpNRLxcV3Rsd6R5U0sUJ+WJyZXFOL0uxzqDPma1WazrVGf7RXhzlDvus+n2H
26p+r6x7Gxz2CQL9kGsKAAAAsAI17gDPhdGYF0bTio+fFdandsoaZGaQ81JL8+WlTqd7SykoTScX
5pydKbSKnErlzYgoJu8fnoX1Dof8VF2pNDtFLIZaUao647NTP+sJBFcEfNasrkCYc+vWXaft6a2e
dUW1eum7R6UhuX2+YvpD9w0ns25x9kA5HtKbzliL6JTUa0sla0Zu0GvPaL8IvarUVy4naPXrlSbl
9PoYdLcDAABs7t+l02kKAJ4pK7XHUgX1h7G/Oe75P//WbFN16mUXa10Fc7zsoZcK/+0f/1Q3XqL+
d+Ufp9KFJe/PpoThV610S1J7MiYqzPG//c9vOtTmytwm8/JfO/7Kmvn79NLl3/ym+C8a/e/0f7k8
81+mPldfS/y98I5nw2z8ktNlKr/LF5R//Sva/Fclm/77z9Ufpv7hbw91jTmp/Uvm72YWncn/yr/1
/S0u07FuV6v8j7//75UW/dI3tWu/+Tvxf5ghYepv/uNfWzP+FXn6X6/+Jpsv1yj6//1/lN+k/8t/
W6TD//Uf/vN/ZHH9DwAAYFPfuXfvHgUAz5R2fTwcXyk1X+MfLRbOrPx2akvJCmNSqWkVojAD0fRU
eqTduW7UcvGwoNw/5AsTlkvZ4c7o6S0lI4xLpbpOHvdy4SQvRDnXw7u0jcaCyKezit0iN5dIS+sv
A2jKRCSad6WLuWRgGx3jWnVOHBfzi1bxO+0O8aKU6D4LMGrzokDWplrP+kMRXkgN+nBjKgAAwFYQ
3AEAAAAAegAuTgMAAAAA9AAEdwAAAACAHoDgDgAAAADQAxDcAQAAAAB6AII7AAAAAEAPQHAHAAAA
AOgBCO4AAAAAAD0AwR0AAAAAoAcguAMAAAAA9AAEdwAAAACAHoDgDgAAAADQAxDcAQAAAAB6AII7
AAAAAEAPQHAHAAAAAOgBCO5P0enTpykAAACA3WR6epqCp+M79+7dowAAAAAAYGdDjzsAAAAAQA9A
cAcAAAAA6AEI7gAAAAAAPQDBHQAAAACgByC4AwAAAAD0AAR3AAAAAIAegOAOAAAAANADENwBAAAA
AHoAgjsAAAAAQA9AcAcAAAAA6AEI7gAAAAAAPQDBHQAAAACgByC4AwAAAAD0AAR3AAAAAIAegOAO
AAAAANAD/n8AAAD///gD3jEAAAAGSURBVAMA41wwaxIo3E8AAAAASUVORK5CYII=
LOANBOOK_FILE
}
commit_19() {
  GIT_AUTHOR_DATE=2026-07-03T17:45:00-03:00 GIT_COMMITTER_DATE=2026-07-03T17:45:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
Explain how to run it and why it is built this way
LOANBOOK_FILE
}

# ---- step 20: License under MIT
step_20() {
  cat > LICENSE <<'LOANBOOK_FILE'
MIT License

Copyright (c) 2026 Ana Lima

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LOANBOOK_FILE
}
commit_20() {
  GIT_AUTHOR_DATE=2026-07-06T09:15:00-03:00 GIT_COMMITTER_DATE=2026-07-06T09:15:00-03:00 git commit -q -F - <<'LOANBOOK_FILE'
License under MIT
LOANBOOK_FILE
  GIT_COMMITTER_DATE=2026-07-06T09:15:00-03:00 git tag -a v1.0.0 -m 'First version worth showing'
}

steps() {
  echo ' 1  2026-06-01  Say what loanbook is for'
  echo ' 2  2026-06-02  Serve a page with nothing on it yet'
  echo ' 3  2026-06-03  List the equipment from SQLite'
  echo ' 4  2026-06-04  Lend an item to somebody'
  echo ' 5  2026-06-05  Take an item back  [v0.1.0]'
  echo ' 6  2026-06-09  Refuse to lend an item that is already out'
  echo ' 7  2026-06-10  Test the loan rules'
  echo ' 8  2026-06-11  Answer every error as JSON'
  echo ' 9  2026-06-12  Say what to do when there is nothing to lend'
  echo '10  2026-06-15  Mark a loan overdue the day after it is due  [v0.2.0]'
  echo '11  2026-06-17  Label every field and announce what happened'
  echo '12  2026-06-18  Fit the table on a phone'
  echo '13  2026-06-22  Refuse a borrower made of spaces'
  echo '14  2026-06-24  Read the database path and port from the environment'
  echo '15  2026-06-25  Answer /healthz so a monitor can ask'
  echo '16  2026-06-26  Build and run in a container'
  echo '17  2026-06-29  Deploy with systemd and Caddy  [v0.3.0]'
  echo '18  2026-07-01  Seed a week that looks real'
  echo '19  2026-07-03  Explain how to run it and why it is built this way'
  echo '20  2026-07-06  License under MIT  [v1.0.0]'
}

case ${1:-} in
  stage)
    rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO"; git init -q -b main
    for i in $(seq 1 "$2"); do "step_$i"; git add -A; "commit_$i"; done ;;
  write) cd "$REPO"; "step_$2" ;;
  steps) steps ;;
  *) echo "usage: lab.sh stage N | write N | steps" >&2; exit 2 ;;
esac
