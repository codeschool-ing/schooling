---
title: idp.py, a toy authorization server
version: 1
---

To see a flow from the inside you need an authorization server you can read, and the ones people
run in production are large. `idp.py` is 222 lines that do the parts this lesson
teaches: `/authorize` with PKCE, `/token` for three grants, an ID token, the discovery document, a
published public key, and two endpoints that play the API. **It is a teaching toy, and the table
at the end of this section lists what it leaves out.**

It does one thing no real server does, so that `curl` can drive it: **it has one user, Ana, who is
always signed in and has already said yes.** Where a real `/authorize` would show a sign-in page
and then a consent screen, this one answers at once with the redirect. Everything after that
moment is real: the codes, the PKCE check, the signatures and the refusals.

Save it as `~/shelf/idp.py` the way you saved `rest.py`.

```schooling-example
{
  "language": "python",
  "file": "shelf/idp.py",
  "parts": [
    {
      "code": "# shelf/idp.py\n\"\"\"A teaching authorization server and OpenID provider for shelf.\n\nOne client, one user, and consent that is already given. Run it with\n`python3 idp.py`; it answers on http://127.0.0.1:8000. It is kept small enough\nto read in one sitting, and that is why it must never face a real user.\n\"\"\"\nimport base64\nimport hashlib\nimport hmac\nimport json\nimport os\nimport secrets\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlencode, urlsplit\n\nimport jwt\nfrom cryptography.hazmat.primitives import serialization\nfrom cryptography.hazmat.primitives.asymmetric import rsa\n\nimport db",
      "note": "Python's standard library, PyJWT for signing tokens, `cryptography` for the RSA key, and `db.py` for the books. All three come from lesson 1's `apt-get` line; nothing is installed here."
    },
    {
      "code": "\nISSUER = \"http://localhost:8000\"\nAPI = \"shelf-api\"\nCLIENT = {\"id\": \"shelf-web\", \"secret\": \"lab-only-secret\",\n          \"redirect_uri\": \"http://127.0.0.1:9000/callback\",\n          \"scopes\": {\"openid\", \"profile\", \"email\", \"books:read\"},\n          \"machine_scopes\": {\"books:read\"}}\nUSER = {\"sub\": \"u-81f3a2\", \"name\": \"Ana Souza\", \"email\": \"ana@shelf.example\"}",
      "note": "**The whole registry is these lines.** One client, with its secret, the one address its codes may be sent to, the scopes a person may grant it and the smaller set it may ask for on its own. One user. `ISSUER` is the name every token carries in `iss`, and `API` is the audience every access token is made out to."
    },
    {
      "code": "\nKEY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"idp-key.pem\")\nif not os.path.exists(KEY_FILE):\n    new = rsa.generate_private_key(public_exponent=65537, key_size=2048)\n    with os.fdopen(os.open(KEY_FILE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), \"wb\") as f:\n        f.write(new.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,\n                                  serialization.NoEncryption()))\nwith open(KEY_FILE, \"rb\") as f:\n    KEY = serialization.load_pem_private_key(f.read(), password=None)\nPUBLIC = KEY.public_key()\nKID = hashlib.sha256(PUBLIC.public_bytes(serialization.Encoding.DER,\n                     serialization.PublicFormat.SubjectPublicKeyInfo)).hexdigest()[:8]\nJWK = {**json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(PUBLIC)), \"kid\": KID, \"use\": \"sig\",\n       \"alg\": \"RS256\"}",
      "note": "The signing key. The first start makes a 2048-bit RSA key and writes it with permissions `0600`, so only you can read it; every later start loads the same one. `KID` is a short fingerprint of the public half, and `JWK` is that public half in the JSON form `/jwks.json` publishes."
    },
    {
      "code": "\nCODES = {}      # code -> what the user granted; works once, for 60 seconds\nREFRESH = {}    # refresh token -> the grant it belongs to, and whether it was used\nREVOKED = set()  # grants ended because one of their refresh tokens came back twice",
      "note": "Three tables in memory. Stopping the server forgets every code and refresh token it ever gave out, which is the first thing a real one would keep in a database."
    },
    {
      "code": "\n\ndef s256(verifier):\n    digest = hashlib.sha256(verifier.encode()).digest()\n    return base64.urlsafe_b64encode(digest).rstrip(b\"=\").decode()\n\n\ndef sign(claims, seconds):\n    now = int(time.time())\n    return jwt.encode({\"iss\": ISSUER, \"iat\": now, \"exp\": now + seconds, **claims},\n                      KEY, algorithm=\"RS256\", headers={\"kid\": KID})",
      "note": "`s256` is PKCE's transformation: SHA-256 of the verifier, in base64url without padding. `sign` makes a JWT signed with the private key, stamped with the issuer, the time it was made and the time it stops being valid."
    },
    {
      "code": "\n\ndef issue(scope, sub=None, grant=None, login=None):\n    \"\"\"The token response: an access token always, the others when they apply.\"\"\"\n    words = \" \".join(sorted(scope))\n    out = {\"token_type\": \"Bearer\", \"expires_in\": 300, \"scope\": words,\n           \"access_token\": sign({\"aud\": API, \"sub\": sub or CLIENT[\"id\"],\n                                 \"client_id\": CLIENT[\"id\"], \"scope\": words,\n                                 \"jti\": secrets.token_hex(8)}, 300)}\n    if grant:\n        refresh = secrets.token_urlsafe(32)\n        REFRESH[refresh] = {\"grant\": grant, \"scope\": scope, \"sub\": sub, \"used\": False}\n        out[\"refresh_token\"] = refresh\n    if login is not None and \"openid\" in scope:\n        out[\"id_token\"] = sign({\"aud\": CLIENT[\"id\"], \"sub\": sub, **login}, 300)\n    return out",
      "note": "**One function writes every token response.** An access token always, for five minutes, made out to the API. A refresh token only when a person granted something, since a machine can simply ask again. An ID token only when a person signed in and the client asked for `openid`."
    },
    {
      "code": "\n\nclass IdP(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Cache-Control\", \"no-store\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def refuse(self, status, error, description, headers=()):\n        self.reply(status, {\"error\": error, \"error_description\": description}, headers)",
      "note": "Every answer leaves through `reply`, as in `rest.py`. A JSON answer carries `Cache-Control: no-store`, because a token in a cache is a token somebody else can be handed. `refuse` writes OAuth's error shape: a code from a fixed list in `error`, and a sentence for people in `error_description`."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        q = {k: v[0] for k, v in parse_qs(url.query).items()}\n        if url.path == \"/authorize\":\n            return self.authorize(q)\n        if url.path == \"/.well-known/openid-configuration\":\n            return self.reply(200, {\n                \"issuer\": ISSUER, \"authorization_endpoint\": ISSUER + \"/authorize\",\n                \"token_endpoint\": ISSUER + \"/token\", \"userinfo_endpoint\": ISSUER + \"/userinfo\",\n                \"jwks_uri\": ISSUER + \"/jwks.json\", \"response_types_supported\": [\"code\"],\n                \"grant_types_supported\": [\"authorization_code\", \"refresh_token\",\n                                          \"client_credentials\"],\n                \"code_challenge_methods_supported\": [\"S256\"],\n                \"scopes_supported\": sorted(CLIENT[\"scopes\"]), \"subject_types_supported\": [\"public\"],\n                \"id_token_signing_alg_values_supported\": [\"RS256\"],\n                \"token_endpoint_auth_methods_supported\": [\"client_secret_basic\"]})\n        if url.path == \"/jwks.json\":\n            return self.reply(200, {\"keys\": [JWK]})\n        if url.path == \"/userinfo\":\n            claims = self.bearer(\"openid\")\n            if claims:\n                scope = claims[\"scope\"].split()\n                info = {\"sub\": claims[\"sub\"]}\n                if \"profile\" in scope:\n                    info[\"name\"] = USER[\"name\"]\n                if \"email\" in scope:\n                    info[\"email\"] = USER[\"email\"]\n                self.reply(200, info)\n            return\n        if url.path == \"/books/stock\":\n            if self.bearer(\"books:read\"):\n                with db.connect() as conn:\n                    rows = conn.execute(\"SELECT id, title, stock FROM books ORDER BY id\").fetchall()\n                self.reply(200, [dict(row) for row in rows])\n            return\n        self.refuse(404, \"not_found\", \"no such endpoint\")",
      "note": "The GET endpoints. Two are public and describe the server: the discovery document and the public key. Two are the **resource server**: `/userinfo` and `/books/stock` answer only to an access token carrying the right scope, and `bearer` below decides that."
    },
    {
      "code": "\n    def authorize(self, q):\n        if q.get(\"client_id\") != CLIENT[\"id\"] or q.get(\"redirect_uri\") != CLIENT[\"redirect_uri\"]:\n            return self.refuse(400, \"invalid_request\", \"unknown client or redirect_uri\")\n\n        def back(**params):\n            if \"state\" in q:\n                params[\"state\"] = q[\"state\"]\n            self.reply(302, None, [(\"Location\", CLIENT[\"redirect_uri\"] + \"?\" + urlencode(params))])\n\n        if q.get(\"response_type\") != \"code\":\n            return back(error=\"unsupported_response_type\")\n        scope = set(q.get(\"scope\", \"\").split())\n        if not scope or not scope <= CLIENT[\"scopes\"]:\n            return back(error=\"invalid_scope\")\n        if q.get(\"code_challenge_method\") != \"S256\" or len(q.get(\"code_challenge\", \"\")) != 43:\n            return back(error=\"invalid_request\", error_description=\"PKCE with S256 is required\")\n        # A real server signs the user in here and shows a consent screen.\n        # This one has one user, who has already said yes to every scope.\n        code = secrets.token_urlsafe(24)\n        CODES[code] = {\"scope\": scope, \"challenge\": q[\"code_challenge\"],\n                       \"login\": {\"nonce\": q[\"nonce\"]} if \"nonce\" in q else {},\n                       \"expires\": time.time() + 60}\n        back(code=code)",
      "note": "`/authorize`. An unknown client or a `redirect_uri` that is not exactly the registered one gets a 400 and **no redirect**, because sending the browser to an address nobody registered is how a code reaches a stranger. Every other refusal goes back to the client's own address with an `error`. Then the code: random, kept for 60 seconds with the scope, the PKCE challenge and the nonce."
    },
    {
      "code": "\n    def client_ok(self):\n        auth = self.headers.get(\"Authorization\", \"\")\n        if not auth.startswith(\"Basic \"):\n            return False\n        given = base64.b64decode(auth[6:]).decode(errors=\"replace\")\n        return hmac.compare_digest(given, CLIENT[\"id\"] + \":\" + CLIENT[\"secret\"])",
      "note": "The client proves who it is with HTTP Basic, the scheme lesson 7 met, and the comparison uses `hmac.compare_digest`, which takes the same time whether the first character or the last one is wrong."
    },
    {
      "code": "\n    def do_POST(self):\n        size = int(self.headers.get(\"Content-Length\") or 0)\n        f = {k: v[0] for k, v in parse_qs(self.rfile.read(size).decode()).items()}\n        if urlsplit(self.path).path != \"/token\":\n            return self.refuse(404, \"not_found\", \"no such endpoint\")\n        if not self.client_ok():\n            return self.refuse(401, \"invalid_client\", \"the client did not authenticate\",\n                               [(\"WWW-Authenticate\", 'Basic realm=\"idp\"')])\n        grant = f.get(\"grant_type\")\n        if grant == \"authorization_code\":\n            c = CODES.pop(f.get(\"code\", \"\"), None)\n            if c is None or c[\"expires\"] < time.time():\n                return self.refuse(400, \"invalid_grant\", \"unknown, used or expired code\")\n            if f.get(\"redirect_uri\") != CLIENT[\"redirect_uri\"]:\n                return self.refuse(400, \"invalid_grant\", \"redirect_uri differs from /authorize\")\n            if not hmac.compare_digest(s256(f.get(\"code_verifier\", \"\")), c[\"challenge\"]):\n                return self.refuse(400, \"invalid_grant\", \"code_verifier does not match\")\n            return self.reply(200, issue(c[\"scope\"], USER[\"sub\"], secrets.token_hex(4), c[\"login\"]))\n        if grant == \"refresh_token\":\n            r = REFRESH.get(f.get(\"refresh_token\", \"\"))\n            if r is None or r[\"grant\"] in REVOKED:\n                return self.refuse(400, \"invalid_grant\", \"unknown or revoked refresh token\")\n            if r[\"used\"]:\n                REVOKED.add(r[\"grant\"])\n                return self.refuse(400, \"invalid_grant\", \"refresh token used twice; grant revoked\")\n            r[\"used\"] = True\n            return self.reply(200, issue(r[\"scope\"], r[\"sub\"], r[\"grant\"]))\n        if grant == \"client_credentials\":\n            scope = set(f.get(\"scope\", \"books:read\").split())\n            if not scope <= CLIENT[\"machine_scopes\"]:\n                return self.refuse(400, \"invalid_scope\", \"a machine may ask for books:read only\")\n            return self.reply(200, issue(scope))\n        self.refuse(400, \"unsupported_grant_type\", f\"{grant} is not offered here\")",
      "note": "`/token`, one branch per grant. A code is taken out of the table **before** it is checked, so it works once even when the check fails. A refresh token is marked used and replaced; one that comes back after that ends its whole grant. Client credentials gets the machine scopes only. Any other grant type is refused by name."
    },
    {
      "code": "\n    def bearer(self, needed):\n        \"\"\"The access token's claims, or None after answering 401 or 403.\"\"\"\n        auth = self.headers.get(\"Authorization\", \"\")\n        if not auth.startswith(\"Bearer \"):\n            self.refuse(401, \"invalid_token\", \"send an access token\",\n                        [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\"')])\n            return None\n        try:\n            claims = jwt.decode(auth[7:], PUBLIC, algorithms=[\"RS256\"], audience=API,\n                                issuer=ISSUER)\n        except jwt.InvalidTokenError as e:\n            self.refuse(401, \"invalid_token\", str(e),\n                        [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\", error=\"invalid_token\"')])\n            return None\n        if needed not in claims[\"scope\"].split():\n            self.refuse(403, \"insufficient_scope\", f\"this needs the scope {needed}\",\n                        [(\"WWW-Authenticate\", f'Bearer error=\"insufficient_scope\", scope=\"{needed}\"')])\n            return None\n        return claims",
      "note": "What an API does with a bearer token, without asking anyone: verify the signature with the public key, refuse any algorithm but RS256, check the issuer, the audience and the expiry, then the scope. No token or a bad one is **401**; a good token without the scope is **403**, and `WWW-Authenticate` names the scope that was missing."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), IdP)\n    print(f\"idp on {ISSUER}, signing key {KID}\", flush=True)\n    server.serve_forever()",
      "note": "Listening on 127.0.0.1 only, on the port `rest.py` uses, so the two cannot run at once. The first line it prints names the key id."
    }
  ]
}
```

## Running it

`idp.py` listens on port 8000, like `rest.py`, so stop `rest.py` first if it is running (`Ctrl+C`
in its terminal). Then, in the second terminal:

```sh
cd ~/shelf && python3 idp.py
```

It prints one line and waits. The id at the end is the key's fingerprint, and yours will be
different because your key is:

```
idp on http://localhost:8000, signing key 420dabcd
```

The first start wrote the private key beside the program, readable by you alone:

```
ana@api:~/shelf$ ls -l idp-key.pem
-rw------- 1 ana ana 1704 Oct 10 01:31 idp-key.pem
```

**That file is the authorization server's whole authority.** Anybody who reads it can sign tokens
every API that trusts this server will accept, for any user and any scope. A real deployment keeps
it in a key store or a hardware module, and the program asks for signatures rather than reading
the key.

## What a real one adds

| `idp.py` | a real authorization server |
|---|---|
| one client, written into the source | registration: many clients, each with its own addresses, scopes and credentials |
| one user, always signed in, consent already given | a sign-in page, passwords stored as lesson 10 describes, a second factor, a consent screen the user can refuse |
| a client secret in the source code | secrets generated per client, stored hashed, rotated; or keys and certificates instead of secrets |
| codes and refresh tokens in memory, forgotten at every restart | a database, and revocations that survive a restart |
| one signing key, for ever | keys rotated on a schedule, the old public key published until the last token it signed has expired |
| plain HTTP on the loopback | HTTPS on every endpoint, since a token on an unencrypted connection is readable by everybody on the path (lesson 13) |
| nothing counts failed attempts | rate limits (lesson 12), audit logs, and an alert when a refresh token is reused |
| no way to revoke a token or ask about one | the revocation endpoint (RFC 7009) and introspection (RFC 7662) |

Use it to see how the pieces fit together. **Never put it, or anything you wrote the same way, in
front of a real user**; the last section of this lesson says what to use instead.
