---
title: keys.py, the books behind a door
version: 1
---

This lesson puts the books of `shelf` behind three kinds of credential at once, in one new file,
`keys.py`. It is a second server rather than a change to `rest.py`, so the API of lesson 1 stays as
it was, and it needs nothing but `db.py` and the database beside it: if you have finished lesson 1,
you have everything it uses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Three columns, one per scheme. Basic sends Authorization: Basic with the name and password in base64 on every request, names a person, and shelf.db keeps an scrypt hash of the password. A bearer token is sent as Authorization: Bearer after one login, names a person, and shelf.db keeps the SHA-256 of the token with an expiry. An API key is sent as X-API-Key on every request, names an application, and shelf.db keeps the visible prefix and the SHA-256 of the key.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sent</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">when</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">names</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shelf.db</text><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">keeps</text><rect x=\"105\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Basic</text><rect x=\"300\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Bearer token</text><rect x=\"495\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API key</text><rect x=\"105\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization:</text><text x=\"195.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Basic YW5h…</text><rect x=\"300\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization:</text><text x=\"390.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Bearer &lt;token&gt;</text><rect x=\"495\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-API-Key:</text><text x=\"585.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shelf_&lt;id&gt;_&lt;secret&gt;</text><text x=\"195\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on every request</text><text x=\"195\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a person</text><text x=\"390\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">after one login</text><text x=\"390\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a person</text><text x=\"585\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on every request</text><text x=\"585\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an application</text><rect x=\"105\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scrypt hash</text><text x=\"195.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">of the password, slow</text><rect x=\"300\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SHA-256</text><text x=\"390.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">of the token, and an expiry</text><rect x=\"495\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prefix + SHA-256</text><text x=\"585.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">of the key, and a name</text><text x=\"390\" y=\"315\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never the secret itself</text></svg>", "caption": "Three doors to the same books. What travels differs, who it names differs, and what is stored is never what travelled."}
```

**Each scheme sends something different, and the server keeps something different for each.** That
is the whole lesson in one drawing, and each column has a section of its own below. What they share
is the bottom row: whatever a client sends, `shelf.db` never holds it as it was sent.

Save the file as `~/shelf/keys.py` with `nano`, the way lesson 1 saved `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/keys.py",
  "parts": [
    {
      "code": "# shelf/keys.py\n\"\"\"The books behind three kinds of credential: Basic, bearer tokens and API keys.\n\nAdd a user with `python3 keys.py adduser NAME`, then run `python3 keys.py`;\nit answers on http://127.0.0.1:8000.\n\"\"\"\nimport base64\nimport getpass\nimport hashlib\nimport hmac\nimport json\nimport re\nimport secrets\nimport sys\nimport time\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Standard library only, like `rest.py`. `hashlib`, `hmac` and `secrets` are the three modules that do the work of this lesson: hashing, comparing and drawing random values."
    },
    {
      "code": "\nTABLES = \"\"\"\nCREATE TABLE IF NOT EXISTS users (\n    id       INTEGER PRIMARY KEY,\n    username TEXT NOT NULL UNIQUE,\n    password_hash TEXT NOT NULL\n);\nCREATE TABLE IF NOT EXISTS tokens (\n    hash    TEXT PRIMARY KEY,\n    user_id INTEGER NOT NULL REFERENCES users (id),\n    expires INTEGER NOT NULL\n);\nCREATE TABLE IF NOT EXISTS api_keys (\n    prefix    TEXT PRIMARY KEY,\n    hash      TEXT NOT NULL,\n    name      TEXT NOT NULL,\n    created   TEXT NOT NULL,\n    last_used TEXT\n);\n\"\"\"\nTOKEN_SECONDS = 3600\n\n\ndef connect():\n    conn = db.connect()\n    conn.executescript(TABLES)\n    return conn",
      "note": "Three tables, created beside the books in `shelf.db` if they are not there yet. **Not one column holds a secret as it was sent**: a password is kept as an scrypt hash, a token and a key as SHA-256. A token lives for an hour."
    },
    {
      "code": "\n\ndef scrypt(password, salt):\n    return hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1, dklen=32)\n\n\ndef hash_password(password):\n    salt = secrets.token_bytes(16)\n    return f\"scrypt${salt.hex()}${scrypt(password, salt).hex()}\"\n\n\nDECOY = hash_password(secrets.token_hex(16))\n\n\ndef check_password(username, password):\n    \"\"\"The user's id if the password is theirs, otherwise None, in the same time.\"\"\"\n    with connect() as conn:\n        row = conn.execute(\"SELECT id, password_hash FROM users WHERE username = ?\",\n                           (username,)).fetchone()\n    _, salt, stored = (row[\"password_hash\"] if row else DECOY).split(\"$\")\n    same = hmac.compare_digest(scrypt(password, bytes.fromhex(salt)).hex(), stored)\n    return row[\"id\"] if row and same else None",
      "note": "The password check. scrypt is slow on purpose, and lesson 10 is about choosing it and its numbers. `DECOY` is a hash of nobody's password: a user who does not exist is checked against it, so the answer takes the same time either way."
    },
    {
      "code": "\n\ndef sha256(secret):\n    return hashlib.sha256(secret.encode()).hexdigest()\n\n\ndef now():\n    return datetime.now(timezone.utc).strftime(\"%Y-%m-%dT%H:%M:%SZ\")",
      "note": "A token and a key are long random strings, not words somebody chose, so a fast hash is enough for them. `now` writes dates in UTC."
    },
    {
      "code": "\n\nclass Keys(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "The same start as `rest.py`: read the whole request first, then answer through one `reply`."
    },
    {
      "code": "\n    def audit(self, line):\n        sys.stderr.write(f\"auth: {line}\\n\")\n\n    def refuse(self, message=\"authentication required\", bearer_error=None):\n        bearer = 'Bearer realm=\"shelf\"'\n        if bearer_error:\n            bearer += f', error=\"{bearer_error}\"'\n        self.reply(401, {\"error\": message},\n                   [(\"WWW-Authenticate\", 'Basic realm=\"shelf\"'), (\"WWW-Authenticate\", bearer)])",
      "note": "`audit` writes one line per decision to the server's terminal. `refuse` is every **401** this file sends, and every one carries a `WWW-Authenticate` for each scheme the API accepts."
    },
    {
      "code": "\n    def who(self):\n        \"\"\"(kind, name) for the credential on this request, or None after answering 401.\"\"\"\n        key = self.headers.get(\"X-API-Key\")\n        if key is not None:\n            return self.by_key(key)\n        scheme, _, credentials = self.headers.get(\"Authorization\", \"\").partition(\" \")\n        if scheme.lower() == \"basic\":\n            return self.by_password(credentials)\n        if scheme.lower() == \"bearer\":\n            return self.by_token(credentials)\n        self.refuse()\n        return None",
      "note": "Which credential came with the request. An `X-API-Key` header is a key; otherwise the scheme word of `Authorization` decides. No credential at all is a 401."
    },
    {
      "code": "\n    def by_password(self, credentials):\n        try:\n            username, _, password = base64.b64decode(credentials, validate=True).decode().partition(\":\")\n        except ValueError:\n            username, password = \"\", \"\"\n        if check_password(username, password) is None:\n            self.audit(f\"basic refused user={username!r}\")\n            self.refuse()\n            return None\n        self.audit(f\"basic ok user={username!r}\")\n        return \"person\", username",
      "note": "**Basic**: base64 decoded back into a name and a password, and the password checked on every request."
    },
    {
      "code": "\n    def by_token(self, token):\n        with connect() as conn:\n            row = conn.execute(\"SELECT username, expires FROM tokens JOIN users ON users.id = user_id\"\n                               \" WHERE hash = ?\", (sha256(token),)).fetchone()\n            if row and row[\"expires\"] <= time.time():\n                conn.execute(\"DELETE FROM tokens WHERE hash = ?\", (sha256(token),))\n                row = None\n        if row is None:\n            self.audit(f\"bearer refused token={sha256(token)[:8]}\")\n            self.refuse(\"invalid or expired token\", \"invalid_token\")\n            return None\n        self.audit(f\"bearer ok user={row['username']!r}\")\n        return \"person\", row[\"username\"]",
      "note": "**Bearer**: the token is hashed and looked up. A row past its expiry is deleted on sight and treated as absent."
    },
    {
      "code": "\n    def by_key(self, key):\n        m = re.fullmatch(r\"(shelf_[0-9a-f]{8})_[\\w-]{43}\", key)\n        with connect() as conn:\n            row = conn.execute(\"SELECT hash, name FROM api_keys WHERE prefix = ?\",\n                               (m.group(1) if m else \"\",)).fetchone()\n            if row and hmac.compare_digest(row[\"hash\"], sha256(key)):\n                conn.execute(\"UPDATE api_keys SET last_used = ? WHERE prefix = ?\", (now(), m.group(1)))\n                self.audit(f\"key ok prefix={m.group(1)}\")\n                return \"application\", row[\"name\"]\n        self.audit(f\"key refused prefix={m.group(1) if m else '?'}\")\n        self.refuse()\n        return None",
      "note": "**API key**: the visible prefix finds the row, `compare_digest` compares the hashes, and `last_used` records that the key is still in use."
    },
    {
      "code": "\n    def person(self):\n        \"\"\"The username, or None after answering 401 or 403.\"\"\"\n        who = self.who()\n        if who and who[0] != \"person\":\n            self.reply(403, {\"error\": \"an API key cannot manage keys\"})\n            return None\n        return who and who[1]",
      "note": "Managing keys is for a person. A key that asks gets **403**: the server knows who it is and says no."
    },
    {
      "code": "\n    def do_GET(self):\n        path = self.path.split(\"?\")[0]\n        if path == \"/v1/keys\":\n            if self.person():\n                with connect() as conn:\n                    rows = conn.execute(\"SELECT prefix, name, created, last_used FROM api_keys\"\n                                        \" ORDER BY created\").fetchall()\n                self.reply(200, [dict(row) for row in rows])\n            return\n        m = re.fullmatch(r\"/v1/(whoami|books|books/(\\d+))\", path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        who = self.who()\n        if who is None:\n            return\n        if m.group(1) == \"whoami\":\n            return self.reply(200, {\"kind\": who[0], \"name\": who[1]})\n        with db.connect() as conn:\n            if m.group(2):\n                row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\",\n                                   (m.group(2),)).fetchone()\n                return self.reply(200, dict(row)) if row else self.reply(404, {\"error\": \"no such book\"})\n            rows = conn.execute(\"SELECT id, title, stock FROM books ORDER BY id\").fetchall()\n        self.reply(200, [dict(row) for row in rows])",
      "note": "Reading. `/v1/whoami` says who the server thinks you are; the books answer with three fields each, enough to see that the door opened."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path == \"/v1/login\":\n            try:\n                value = json.loads(self.raw)\n                user = check_password(str(value[\"username\"]), str(value[\"password\"]))\n            except (ValueError, KeyError, TypeError):\n                return self.reply(400, {\"error\": \"send username and password as JSON\"})\n            if user is None:\n                self.audit(f\"login refused user={value['username']!r}\")\n                return self.refuse(\"wrong username or password\")\n            token = secrets.token_urlsafe(32)\n            expires = int(time.time()) + TOKEN_SECONDS\n            with connect() as conn:\n                conn.execute(\"INSERT INTO tokens VALUES (?, ?, ?)\", (sha256(token), user, expires))\n            self.audit(f\"login ok user={value['username']!r}\")\n            return self.reply(200, {\"token\": token, \"expires_in\": TOKEN_SECONDS})\n        if self.path == \"/v1/logout\":\n            scheme, _, token = self.headers.get(\"Authorization\", \"\").partition(\" \")\n            with connect() as conn:\n                gone = conn.execute(\"DELETE FROM tokens WHERE hash = ?\", (sha256(token),)).rowcount\n            if scheme.lower() == \"bearer\" and gone:\n                return self.reply(204)\n            return self.refuse(\"invalid or expired token\", \"invalid_token\")\n        if self.path == \"/v1/keys\":\n            if not self.person():\n                return\n            try:\n                name = str(json.loads(self.raw)[\"name\"])\n            except (ValueError, KeyError, TypeError):\n                return self.reply(400, {\"error\": \"send the key's name as JSON\"})\n            prefix = \"shelf_\" + secrets.token_hex(4)\n            key = f\"{prefix}_{secrets.token_urlsafe(32)}\"\n            with connect() as conn:\n                conn.execute(\"INSERT INTO api_keys (prefix, hash, name, created) VALUES (?, ?, ?, ?)\",\n                             (prefix, sha256(key), name, now()))\n            return self.reply(201, {\"key\": key, \"prefix\": prefix, \"name\": name,\n                                    \"note\": \"shown once: store it now\"})\n        self.reply(404, {\"error\": \"no such resource\"})",
      "note": "Three writes. `/v1/login` swaps a password for a token, `/v1/logout` deletes the token's row, and `/v1/keys` creates a key and shows it this once."
    },
    {
      "code": "\n    def do_DELETE(self):\n        m = re.fullmatch(r\"/v1/keys/(shelf_[0-9a-f]{8})\", self.path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        if self.person():\n            with connect() as conn:\n                gone = conn.execute(\"DELETE FROM api_keys WHERE prefix = ?\", (m.group(1),)).rowcount\n            if gone:\n                return self.reply(204)\n            self.reply(404, {\"error\": \"no such key\"})",
      "note": "Revoking a key is deleting its row, by its prefix."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if sys.argv[1:2] == [\"adduser\"]:\n        name = sys.argv[2]\n        password = getpass.getpass() if sys.stdin.isatty() else sys.stdin.readline().rstrip(\"\\n\")\n        with connect() as conn:\n            conn.execute(\"INSERT INTO users (username, password_hash) VALUES (?, ?)\",\n                         (name, hash_password(password)))\n        print(f\"user {name} added\")\n    else:\n        server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Keys)\n        print(\"keys on http://127.0.0.1:8000\", flush=True)\n        server.serve_forever()",
      "note": "`adduser` stores a user. At a terminal it asks for the password without showing it; from a pipe it reads one line. Anything else starts the server."
    }
  ]
}
```

## Running it

`keys.py` listens on the same port as `rest.py`, so stop `rest.py` in the second terminal with
`Ctrl+C` first. Then, in the first terminal, add a user. The file has no sign-up page, so a user is
added from the command line:

```
ana@api:~/shelf$ ls
db.py
keys.py
rest.py
ana@api:~/shelf$ printf 'river-lamp-42\n' | python3 keys.py adduser ana
user ana added
```

Typed at a terminal, `python3 keys.py adduser ana` asks `Password:` and shows nothing while you type.
The capture above pipes the password in instead, because a recording has no keyboard; at your own
terminal, leave the `printf` out. Then look at what was stored:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|scrypt$0091e3c7013068c5f51c65cd7361c6a4$cd3175e0712e0adab9db597d995ed63cf962848cd76bc98857b40f785ad0a501
```

**That row cannot be turned back into `river-lamp-42`.** It is three fields joined by `$`: the name of
the function, a random salt, and the result. Checking a password means running the same function on
what somebody sends, with the same salt, and comparing results. Why the function is scrypt, why the
salt is there and how slow it should be is lesson 10; here it is a box that takes a password and
answers yes or no.

Now start the server in the second terminal:

```sh
cd ~/shelf && python3 keys.py
```

It prints `keys on http://127.0.0.1:8000` and, like `rest.py`, one line per request. It also prints a
line starting with `auth:` for every decision it makes about a credential; the section on saying
nothing reads them.
