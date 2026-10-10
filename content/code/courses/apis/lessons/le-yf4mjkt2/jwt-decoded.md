```schooling-example
{
  "language": "python",
  "file": "shelf/tokens.py",
  "parts": [
    {
      "code": "# shelf/tokens.py\n\"\"\"Signing in with a JWT: the token says who you are, and the server's key vouches for it.\n\nRun it with `python3 tokens.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport os\nimport secrets\nimport time\nfrom http.server import ThreadingHTTPServer\n\nimport jwt\n\nimport sessions\nfrom sessions import digest",
      "note": "PyJWT, imported as `jwt`, is the `python3-jwt` package lesson 1 installed. The users, the password check and the request plumbing are `sessions.py`'s, imported rather than copied, so the two servers differ only in how they remember you."
    },
    {
      "code": "\nISSUER, AUDIENCE = \"shelf\", \"shelf-api\"\nACCESS_LIFETIME = 5 * 60\nREFRESH_LIFETIME = 14 * 24 * 60 * 60\nLEEWAY = 30",
      "note": "The names that go into `iss` and `aud`, the two lifetimes, and how many seconds of clock difference to forgive. Five minutes for an access token is short on purpose, and the section on revocation is why."
    },
    {
      "code": "\n\ndef signing_key():\n    \"\"\"32 random bytes in jwt.key, made on first use and readable by its owner only.\"\"\"\n    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"jwt.key\")\n    if not os.path.exists(path):\n        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)\n        os.write(fd, secrets.token_bytes(32))\n        os.close(fd)\n    with open(path, \"rb\") as f:\n        return f.read()\n\n\nKEY = signing_key()",
      "note": "The HMAC key: 32 random bytes in `jwt.key`, created on first use with permissions `600`. **Whoever can read this file can sign tokens the API believes**, so it is a secret like a database password, and it never goes into source code or a repository."
    },
    {
      "code": "\n\ndef connect():\n    conn = sessions.connect()\n    conn.executescript(\"\"\"\n        CREATE TABLE IF NOT EXISTS refresh_tokens (\n            id_hash TEXT PRIMARY KEY,\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            family  TEXT NOT NULL,\n            expires INTEGER NOT NULL,\n            used    INTEGER NOT NULL DEFAULT 0);\n        CREATE TABLE IF NOT EXISTS revoked (\n            jti TEXT PRIMARY KEY,\n            exp INTEGER NOT NULL);\n    \"\"\")\n    return conn",
      "note": "Two tables for what a JWT cannot do alone: the refresh tokens, stored by their hash like the sessions, and the denylist of revoked token ids."
    },
    {
      "code": "\n\ndef issue(user_id, now=None):\n    \"\"\"A signed access token for the user, valid for ACCESS_LIFETIME seconds from now.\"\"\"\n    now = int(time.time() if now is None else now)\n    claims = {\"sub\": str(user_id), \"iss\": ISSUER, \"aud\": AUDIENCE, \"iat\": now, \"nbf\": now,\n              \"exp\": now + ACCESS_LIFETIME, \"jti\": secrets.token_hex(8)}\n    return jwt.encode(claims, KEY, algorithm=\"HS256\")",
      "note": "The claims, then `jwt.encode` signs them with HS256. Nothing about the login is written down here: the token is the whole record."
    },
    {
      "code": "\n\ndef verify(conn, token):\n    \"\"\"The claims of a good access token; raises jwt.InvalidTokenError for any other.\"\"\"\n    claims = jwt.decode(token, KEY, algorithms=[\"HS256\"], issuer=ISSUER, audience=AUDIENCE,\n                        leeway=LEEWAY,\n                        options={\"require\": [\"sub\", \"iss\", \"aud\", \"iat\", \"nbf\", \"exp\", \"jti\"]})\n    if conn.execute(\"SELECT 1 FROM revoked WHERE jti = ?\", (claims[\"jti\"],)).fetchone():\n        raise jwt.InvalidTokenError(\"token revoked\")\n    return claims",
      "note": "`algorithms=[\"HS256\"]` is the line that matters most. The server decides how a token must be signed, and a token that says otherwise is refused. Then the issuer, the audience, the times with 30 seconds of leeway, and all seven claims required. The last check reads the denylist, which is one lookup on every request."
    },
    {
      "code": "\n\ndef pair(conn, user_id, family=None):\n    \"\"\"A new access token and a new refresh token, the second remembered by its hash.\"\"\"\n    refresh = secrets.token_urlsafe(32)\n    conn.execute(\"INSERT INTO refresh_tokens VALUES (?, ?, ?, ?, 0)\",\n                 (digest(refresh), user_id, family or secrets.token_hex(8),\n                  int(time.time()) + REFRESH_LIFETIME))\n    return {\"access_token\": issue(user_id), \"token_type\": \"Bearer\",\n            \"expires_in\": ACCESS_LIFETIME, \"refresh_token\": refresh}",
      "note": "Login and refresh both answer with a pair: a short-lived access token and a long-lived refresh token. The refresh token is a random string, not a JWT, and its `family` ties together every token descended from one login."
    },
    {
      "code": "\n\nclass Tokens(sessions.Handler):\n\n    def bearer(self, conn):\n        \"\"\"The claims of the request's access token, or None after answering 401.\"\"\"\n        scheme, _, token = self.headers.get(\"Authorization\", \"\").partition(\" \")\n        problem = \"send Authorization: Bearer <token>\"\n        if scheme == \"Bearer\" and token:\n            try:\n                return verify(conn, token)\n            except jwt.InvalidTokenError as e:\n                problem = str(e)\n        self.error(401, problem, [(\"WWW-Authenticate\", 'Bearer error=\"invalid_token\"')])\n        return None\n\n    def do_GET(self):\n        if self.path != \"/me\":\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            claims = self.bearer(conn)\n            if claims is not None:\n                name = conn.execute(\"SELECT name FROM users WHERE id = ?\", (claims[\"sub\"],)).fetchone()\n                self.reply(200, {\"name\": name[\"name\"], \"exp\": claims[\"exp\"], \"jti\": claims[\"jti\"]})",
      "note": "The token arrives in `Authorization: Bearer`. A missing or bad one gets **401** with `WWW-Authenticate: Bearer`, and the body names the check that failed. `/me` finds the user from `sub`."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path not in (\"/login\", \"/refresh\", \"/logout\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            if self.path == \"/login\":\n                user = self.login(conn)\n                if user is not None:\n                    self.reply(200, pair(conn, user))\n                return",
      "note": "Login is the check from `sessions.py`, answered with a pair instead of a cookie."
    },
    {
      "code": "            if self.path == \"/logout\":\n                claims = self.bearer(conn)\n                if claims is not None:\n                    conn.execute(\"DELETE FROM revoked WHERE exp < ?\", (int(time.time()),))\n                    conn.execute(\"INSERT INTO revoked VALUES (?, ?)\", (claims[\"jti\"], claims[\"exp\"]))\n                    conn.execute(\"DELETE FROM refresh_tokens WHERE user_id = ?\", (claims[\"sub\"],))\n                    self.reply(204)\n                return",
      "note": "Logout puts the token's `jti` on the denylist until its `exp`, pruning entries that have expired anyway, and deletes the user's refresh tokens, which signs them out on every device at once."
    },
    {
      "code": "            value = self.body()\n            if value is None:\n                return\n            row = conn.execute(\"SELECT * FROM refresh_tokens WHERE id_hash = ? AND expires > ?\",\n                               (digest(str(value.get(\"refresh_token\"))), int(time.time()))).fetchone()\n            if row is None:\n                return self.error(401, \"unknown or expired refresh token\")\n            if row[\"used\"]:\n                conn.execute(\"DELETE FROM refresh_tokens WHERE family = ?\", (row[\"family\"],))\n                return self.error(401, \"refresh token used twice: this sign-in is revoked\")\n            conn.execute(\"UPDATE refresh_tokens SET used = 1 WHERE id_hash = ?\", (row[\"id_hash\"],))\n            self.reply(200, pair(conn, row[\"user_id\"], row[\"family\"]))",
      "note": "Refresh with **rotation**: a refresh token works once and comes back replaced. One presented a second time means two parties hold it, so its whole family is deleted and both must sign in again."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Tokens)\n    print(\"tokens on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "Port 8000 again: stop `sessions.py` before starting this one."
    }
  ]
}
```
