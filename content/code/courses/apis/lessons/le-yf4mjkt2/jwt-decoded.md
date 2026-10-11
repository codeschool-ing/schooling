---
title: A JWT, decoded
version: 1
---

A JWT, a JSON Web Token, is three pieces of base64url joined by dots: a **header** that says how the
token was signed, a **payload** of claims about the user, and a **signature** over the first two.
The header and the payload are encoded, not encrypted. Anyone holding the token can read them, and
this section does it by hand.

That corrects the most common belief about JWTs, that the long string is opaque and therefore a safe
place for data. It is opaque only to a person who has not tried `base64 -d`. **The signature stops
anyone without the key changing the claims unnoticed; nothing stops anyone reading them.** A token that has to hide its
contents is a different format, JWE, which is rarely used; what everyone calls a JWT is the signed
kind.

## The file

`tokens.py` signs ana in with a JWT. It imports `sessions.py` for the users, the password check and
the request plumbing, so both files must be in `~/shelf`. Save it with `nano tokens.py`.

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

Stop `sessions.py` in the second terminal with `Ctrl+C` and start this one:

```sh
cd ~/shelf && python3 tokens.py
```

## Logging in

The login is the same request, and the answer is different: no cookie, a JSON body with two tokens
in it. `tee login.json` keeps that body in a file, so the commands after this one can read the token
out of it with `jq`:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}' | tee login.json | jq .
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkiLCJpYXQiOjE3OTE2MDY2NjcsIm5iZiI6MTc5MTYwNjY2NywiZXhwIjoxNzkxNjA2OTY3LCJqdGkiOiIxOTAyYTFhY2FhNDNiMzE2In0.6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "2D7viIKQ5cVy58OnUMwMza_z8_kb7pPMLaHwUWMJ02U"
}
```

`/me` wants the access token in `Authorization: Bearer`, the scheme lesson 7 introduced. With no
token, the answer is 401, and `WWW-Authenticate` names the scheme the client should use:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"
{"name": "ana", "exp": 1791606967, "jti": "1902a1acaa43b316"}
ana@api:~/shelf$ curl -si localhost:8000/me
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:07 GMT
Content-Type: application/json
Content-Length: 48
WWW-Authenticate: Bearer error="invalid_token"

{"error": "send Authorization: Bearer <token>"}
```

The first run also created the signing key. It is readable by ana alone:

```
ana@api:~/shelf$ ls -l jwt.key
-rw------- 1 ana ana 32 Oct 10 01:31 jwt.key
```

## Reading it by hand

Split the access token at its dots. The first piece is the header, and `base64 -d` reads it:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f1 | base64 -d; echo
{"alg":"HS256","typ":"JWT"}
```

The second piece is the payload. JWTs use **base64url**, the variant with `-` and `_` where plain
base64 has `+` and `/`, so it can sit in a URL; `basenc --base64url` decodes that alphabet. It prints
the JSON, then complains:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | basenc --base64url -d; echo
{"sub":"1","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}basenc: invalid input
```

The JSON is all there; the complaint is about the end. Base64 works in groups of four characters
and pads the last group with `=`. Base64url as JWTs use it **drops the padding**, so a piece whose
length is not a multiple of four looks truncated to a strict decoder. This one is 159 characters:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | tr -d "\n" | wc -c
159
```

One `=` makes 160, and the decoder is satisfied:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | sed 's/$/=/' | basenc --base64url -d; echo
{"sub":"1","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"A JWT split at its two dots into three base64url parts. The first decodes to the header, alg HS256 and typ JWT. The second decodes to the payload, seven claims: sub, iss, aud, iat, nbf, exp and jti. The third is the signature, HMAC-SHA256 over the first two parts and the dot between them, made with the key in jwt.key. The first two are only encoded and anyone can read them; only the third needs the key.\"><defs><marker id=\"l08-jwt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"12\" width=\"680\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eyJhbGciOiJIUzI1NiIsIn…</text><text x=\"196\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.</text><text x=\"206\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQi…</text><text x=\"530\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.</text><text x=\"540\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6htCZVCQFrI9WiAk…</text><line x1=\"100\" y1=\"46\" x2=\"100\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><line x1=\"360\" y1=\"46\" x2=\"360\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><line x1=\"600\" y1=\"46\" x2=\"600\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><rect x=\"10\" y=\"80\" width=\"180\" height=\"110\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">header</text><text x=\"22\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;alg&quot;: &quot;HS256&quot;</text><text x=\"22\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;typ&quot;: &quot;JWT&quot;</text><text x=\"100\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">how it was signed</text><rect x=\"210\" y=\"80\" width=\"300\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">payload: the claims</text><text x=\"222\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;sub&quot;: &quot;1&quot;</text><text x=\"498\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">who: user 1, ana</text><text x=\"222\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;iss&quot;: &quot;shelf&quot;</text><text x=\"498\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">who issued it</text><text x=\"222\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;aud&quot;: &quot;shelf-api&quot;</text><text x=\"498\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">who it is for</text><text x=\"222\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;iat&quot;: 1791606667</text><text x=\"498\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">issued at</text><text x=\"222\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;nbf&quot;: 1791606667</text><text x=\"498\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not valid before</text><text x=\"222\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;exp&quot;: 1791606967</text><text x=\"498\" y=\"242\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">expires, 300 s later</text><text x=\"222\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;jti&quot;: &quot;1902a1acaa43b316&quot;</text><text x=\"498\" y=\"266\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">this token&#x27;s id</text><rect x=\"530\" y=\"80\" width=\"160\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">signature</text><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HMAC-SHA256(</text><text x=\"610\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">jwt.key,</text><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">header.payload</text><text x=\"610\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">)</text><text x=\"610\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">32 bytes, then</text><text x=\"610\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">base64url</text><text x=\"250\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">encoded: anyone holding the token reads these</text><line x1=\"20\" y1=\"316\" x2=\"500\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"610\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">needs the key</text><line x1=\"530\" y1=\"316\" x2=\"690\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line></svg>", "caption": "The access token from the login above, decoded. Two of its three parts are plain JSON in base64url; the third is the only one that needs the key."}
```

Seven claims in 159 characters, readable by the browser, by every proxy and log that sees the
header, and by whoever finds the token in a screenshot. So **a payload carries identifiers and times,
never secrets**: not a password, not a card number, not an address you would not print on the
outside of an envelope. The section on claims takes the seven one by one.
