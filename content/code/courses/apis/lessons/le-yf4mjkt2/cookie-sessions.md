---
title: A session in a cookie
version: 1
---

A session login has three steps. The client sends a name and a password once. The server checks
them, writes a row saying "this random id is ana's until a given time", and sends the id back in a
`Set-Cookie` header. From then on the client returns the id in a `Cookie` header on every request,
and the server finds the row. **The id is the whole credential**, and it carries no information:
there is nothing in it to read and nothing to forge, only something to guess, and 32 random bytes
cannot be guessed.

## The file

`sessions.py` is that, for shelf. Save it in `~/shelf` with `nano sessions.py`, the way lesson 1
saved `rest.py`.

```schooling-example
{
  "language": "python",
  "file": "shelf/sessions.py",
  "parts": [
    {
      "code": "# shelf/sessions.py\n\"\"\"Signing in with a session cookie: the server remembers you in a row.\n\nRun it with `python3 sessions.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport hashlib\nimport hmac\nimport json\nimport secrets\nimport time\nfrom http.cookies import SimpleCookie\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Only the standard library and `db.py`, like `rest.py`. `http.cookies` is what reads the `Cookie` header a client sends back."
    },
    {
      "code": "\nLIFETIME = 30 * 60\n\n# The lab's two accounts. Never put a real password in a source file.\nUSERS = [(1, \"ana\", \"correct-horse\"), (2, \"bruno\", \"battery-staple\")]",
      "note": "A session lasts thirty minutes, counted in seconds. The two accounts carry their passwords in the file only because this is a lab; lesson 10 is about where a password really goes."
    },
    {
      "code": "\n\ndef scrypt(password, salt):\n    return hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1)\n\n\ndef connect():\n    \"\"\"shelf.db, with the users, sessions and wishlist tables added to it.\"\"\"\n    conn = db.connect()\n    conn.executescript(\"\"\"\n        CREATE TABLE IF NOT EXISTS users (\n            id   INTEGER PRIMARY KEY,\n            name TEXT NOT NULL UNIQUE,\n            salt BLOB NOT NULL,\n            hash BLOB NOT NULL);\n        CREATE TABLE IF NOT EXISTS sessions (\n            id_hash TEXT PRIMARY KEY,\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            csrf    TEXT NOT NULL,\n            expires INTEGER NOT NULL);\n        CREATE TABLE IF NOT EXISTS wishlist (\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            book_id INTEGER NOT NULL REFERENCES books (id),\n            PRIMARY KEY (user_id, book_id));\n    \"\"\")\n    if conn.execute(\"SELECT count(*) FROM users\").fetchone()[0] == 0:\n        for ident, name, password in USERS:\n            salt = secrets.token_bytes(16)\n            conn.execute(\"INSERT INTO users VALUES (?, ?, ?, ?)\",\n                         (ident, name, salt, scrypt(password, salt)))\n        conn.commit()\n    return conn",
      "note": "Three tables join the two `db.py` made, each created only if it is missing. A password is kept as a random salt and the scrypt of the password with that salt, **never as itself**. `hashlib.scrypt` is in the standard library, and lesson 10 sets it beside bcrypt and Argon2."
    },
    {
      "code": "\n\ndef check_login(conn, name, password):\n    \"\"\"The user's id, or None. A name nobody has costs the same as a wrong password.\"\"\"\n    row = conn.execute(\"SELECT id, salt, hash FROM users WHERE name = ?\", (name,)).fetchone()\n    if row is None:\n        scrypt(password, bytes(16))\n        return None\n    return row[\"id\"] if hmac.compare_digest(scrypt(password, row[\"salt\"]), row[\"hash\"]) else None\n\n\ndef digest(token):\n    return hashlib.sha256(token.encode()).hexdigest()",
      "note": "A name nobody has still costs one scrypt, so a wrong name and a wrong password take the same time and get the same answer; otherwise the login form tells a stranger who has an account. `digest` is SHA-256, applied to every random token before it touches the database."
    },
    {
      "code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    \"\"\"Reading requests and writing answers, the way rest.py does.\"\"\"\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)\n\n    def body(self):\n        \"\"\"The request's JSON object, or None after answering 415 or 400.\"\"\"\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            self.error(415, \"send application/json\")\n            return None\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            value = None\n        if not isinstance(value, dict):\n            self.error(400, \"the body must be a JSON object\")\n            return None\n        return value\n\n    def login(self, conn):\n        \"\"\"The user id for the name and password in the body, or None after answering.\"\"\"\n        value = self.body()\n        if value is None:\n            return None\n        user = check_login(conn, str(value.get(\"name\", \"\")), str(value.get(\"password\", \"\")))\n        if user is None:\n            self.error(401, \"wrong name or password\")\n        return user",
      "note": "The plumbing `rest.py` already has: read the whole request, answer with a length, read a JSON body. `login` adds the check above and answers **401** when it fails. `tokens.py` reuses this whole class."
    },
    {
      "code": "\n\nclass Sessions(Handler):\n\n    def session(self, conn):\n        \"\"\"The live session named by the request's cookie, or None.\"\"\"\n        cookie = SimpleCookie(self.headers.get(\"Cookie\", \"\"))\n        if \"sid\" not in cookie:\n            return None\n        return conn.execute(\n            \"SELECT s.id_hash, s.user_id, s.csrf, u.name FROM sessions s\"\n            \" JOIN users u ON u.id = s.user_id WHERE s.id_hash = ? AND s.expires > ?\",\n            (digest(cookie[\"sid\"].value), int(time.time()))).fetchone()\n\n    def do_GET(self):\n        if self.path not in (\"/me\", \"/wishlist\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            s = self.session(conn)\n            if s is None:\n                return self.error(401, \"sign in first\")\n            if self.path == \"/me\":\n                return self.reply(200, {\"name\": s[\"name\"], \"csrf\": s[\"csrf\"]})\n            rows = conn.execute(\"SELECT b.id, b.title FROM wishlist w JOIN books b ON b.id = w.book_id\"\n                                \" WHERE w.user_id = ? ORDER BY b.id\", (s[\"user_id\"],)).fetchall()\n            return self.reply(200, [dict(row) for row in rows])",
      "note": "A session is looked up by the **hash** of the cookie's value, and only while `expires` is in the future. The server enforces the thirty minutes itself, whatever a client does with `Max-Age`. `/me` says who you are and hands back the session's CSRF token."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path not in (\"/login\", \"/logout\", \"/wishlist\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            if self.path == \"/login\":\n                user = self.login(conn)\n                if user is None:\n                    return\n                sid = secrets.token_urlsafe(32)\n                conn.execute(\"INSERT INTO sessions VALUES (?, ?, ?, ?)\",\n                             (digest(sid), user, secrets.token_urlsafe(32), int(time.time()) + LIFETIME))\n                cookie = f\"sid={sid}; Path=/; Max-Age={LIFETIME}; HttpOnly; Secure; SameSite=Lax\"\n                return self.reply(204, headers=[(\"Set-Cookie\", cookie)])",
      "note": "A good login makes a new random id from 32 bytes of `secrets`, stores its hash with the user, a CSRF token and an expiry, and sends the id itself once, in `Set-Cookie`. The id is new at every login and never one the client proposed."
    },
    {
      "code": "            s = self.session(conn)\n            if s is None:\n                return self.error(401, \"sign in first\")\n            sent = self.headers.get(\"X-CSRF-Token\", \"\").encode()\n            if not hmac.compare_digest(sent, s[\"csrf\"].encode()):\n                return self.error(403, \"missing or wrong X-CSRF-Token\")\n            if self.path == \"/logout\":\n                conn.execute(\"DELETE FROM sessions WHERE id_hash = ?\", (s[\"id_hash\"],))\n                gone = \"sid=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax\"\n                return self.reply(204, headers=[(\"Set-Cookie\", gone)])\n            value = self.body()\n            if value is None:\n                return\n            if conn.execute(\"SELECT 1 FROM books WHERE id = ?\", (value.get(\"book_id\"),)).fetchone() is None:\n                return self.error(422, \"no such book\")\n            conn.execute(\"INSERT OR IGNORE INTO wishlist VALUES (?, ?)\", (s[\"user_id\"], value[\"book_id\"]))\n            return self.reply(201, {\"book_id\": value[\"book_id\"]})",
      "note": "Every other `POST` needs a live session **and** that session's token in `X-CSRF-Token`, or it gets 403. Logout deletes the row and tells the client to drop the cookie with `Max-Age=0`. The wishlist exists so that there is something a forged request could change."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Sessions)\n    print(\"sessions on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "The same address as `rest.py`, so only one of them runs at a time."
    }
  ]
}
```

If `rest.py` is still running in your second terminal, stop it with `Ctrl+C`; then start this one in
its place:

```sh
cd ~/shelf && python3 sessions.py
```

## Logging in

curl does not remember cookies unless asked. `-c jar.txt` writes every cookie the server sets into a
file, the **cookie jar**, and `-b jar.txt` sends them back. Log in as ana, with `-i` to see the
headers:

```
ana@api:~/shelf$ curl -si -c jar.txt localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}'
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Length: 0
Set-Cookie: sid=kr6NIl3Zl2MI3d3XSey1PcqabSRq9R3JpTLrnPuvQB0; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
```

There is no body: **204** says it worked, and the answer is the header. The cookie is a name and a
value, `sid` and 43 characters of base64url, followed by **attributes** that tell the client how to
treat it. None of them is sent back to the server; they are instructions, and each one closes a
particular door.

| attribute | what it tells the client | without it |
|---|---|---|
| `Path=/` | send it with requests to every path on this host | the client picks a default from the address that set it, and a login at `/v1/login` would get a cookie for `/v1` only |
| `Max-Age=1800` | forget it after 1800 seconds | it lasts until the browser closes, and a browser that restores its tabs never quite does |
| `HttpOnly` | never show it to the page's JavaScript | any script in the page can read it, including one an attacker injected |
| `Secure` | send it over HTTPS only | it crosses plain HTTP too, readable by anyone on the network path |
| `SameSite=Lax` | leave it off requests that other sites start, apart from following a link | another site's page can make the browser send it; the section on CSRF |

**One attribute is missing on purpose.** With no `Domain`, the cookie belongs to this exact host and
is not sent to its subdomains. `Domain=example.com` would share it with every `*.example.com`,
including one that somebody else runs.

`Max-Age` is a request to the client, and a client may ignore it, keep the cookie, or copy it
somewhere. So `sessions.py` keeps its own expiry in the row, and refuses an id past that time
whatever the cookie said. The rule that runs through the whole lesson starts here: **the server
enforces; the attributes only help a well-behaved client.**

## The jar

The jar is a text file in the format Netscape's browser used, one cookie per line:

```
ana@api:~/shelf$ cat jar.txt
# Netscape HTTP Cookie File
# https://curl.se/docs/http-cookies.html
# This file was generated by libcurl! Edit at your own risk.

#HttpOnly_localhost	FALSE	/	TRUE	1791608466	sid	kr6NIl3Zl2MI3d3XSey1PcqabSRq9R3JpTLrnPuvQB0
```

The columns are the host, whether subdomains get it (`FALSE`, because there was no `Domain`), the
path, whether it is `Secure` (`TRUE`), the expiry in seconds since 1970, the name and the value. curl
records `HttpOnly` by putting `#HttpOnly_` in front of the host, so a tool that reads only
uncommented lines skips the cookie. A browser keeps the same facts in a database of its own.

With the jar the server knows you; without it, it does not:

```
ana@api:~/shelf$ curl -s -b jar.txt localhost:8000/me
{"name": "ana", "csrf": "3xdPJTXc4XNCVCO8j9gEGxoTFXcXxxhjLgoIzjnqxJ4"}
ana@api:~/shelf$ curl -si localhost:8000/me
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Type: application/json
Content-Length: 27

{"error": "sign in first"}
```

`/me` also returned a `csrf` value, which the section on cross-site requests uses.

## The row

The server's half is a row in `shelf.db`:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id_hash, user_id, expires FROM sessions'
e9a4c1c74f4a350137338bca3bc868f54e4db4175ea6a12b689e8c4d9725c341|1|1791608466
```

**The table does not hold the id, it holds the SHA-256 of the id.** Hash the value from the jar and
you get the same 64 hex characters:

```
ana@api:~/shelf$ awk '$6 == "sid" {printf "%s", $7}' jar.txt | sha256sum
e9a4c1c74f4a350137338bca3bc868f54e4db4175ea6a12b689e8c4d9725c341  -
```

The server can still find the row, by hashing the cookie it receives. What it no longer has is the
id itself, so a copy of the database, a backup somebody left on a share for instance, gives its
reader rows and no cookie that would work. SHA-256 is enough here, where lesson 10 will insist on
something far slower for passwords: a session id is 32 random bytes, and there is no list of likely
values to try.

## Two refusals

`Secure` means what it says. curl treats `localhost` as secure even over plain HTTP, as browsers do,
which is why the jar above has the cookie. Ask for the same server under another name, which
`--resolve` points at this machine, and the `Secure` cookie arrives over plain HTTP and is dropped:

```
ana@api:~/shelf$ curl -si -c shop.txt --resolve shop.test:8000:127.0.0.1 http://shop.test:8000/login -H 'Content-Type: application/json' -d '{"name": "bruno", "password": "battery-staple"}'
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Length: 0
Set-Cookie: sid=2lZcbYKu970J_2qU4i1hI-Ui5REr-bVd2nH6VOOKQrM; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax

ana@api:~/shelf$ cat shop.txt
# Netscape HTTP Cookie File
# https://curl.se/docs/http-cookies.html
# This file was generated by libcurl! Edit at your own risk.
```

The jar is empty. The server set the cookie; the client refused to keep it.

And a wrong password and a name nobody has get **the same answer**, so the login form cannot be used
to find out who has an account. `check_login` also spends one scrypt on the unknown name, so the two
take the same time:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-hors"}'
{"error": "wrong name or password"}
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "anna", "password": "correct-horse"}'
{"error": "wrong name or password"}
```
