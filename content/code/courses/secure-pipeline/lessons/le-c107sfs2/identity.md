---
title: "Federated identity: the run proves who it is"
version: 1
---

**A run does not need a secret to prove who it is; it needs somebody both sides trust to say so.**
The CI server started the run, so it knows the repository and the branch better than anything the
run could claim about itself. If the server signs that statement with a private key, and Vault holds
the matching public key, Vault can check every statement the server makes and believe the ones whose
signature holds. The run carries the signed statement for a few minutes and nothing else.

The format almost everybody uses for that statement is a **JSON Web Token**, a JWT, and the protocol
that publishes the keys and names the fields is OpenID Connect, which is why this is usually called
"OIDC" in CI documentation. GitHub Actions, GitLab CI, CircleCI and Buildkite all issue these tokens. This section makes your CI server issue them too.

### The CI server's key

The private key is the new thing to protect, and it belongs with the CI server's other keys, outside
any repository. Make it, and derive the public half that Vault will be given:

@@CAPTURE keys@@

`pkey -pubout` writes the public key, which is not a secret: anybody may hold it, because it can only
check signatures, not make them. Notice what just happened to the secret zero problem. There is still one long-lived
secret, the private key, but it never leaves the CI server and **no run ever holds it**. A run holds
a token that the key signed, and the token dies in five minutes.

### The program that mints the tokens

Real CI services build these tokens inside their own servers. Yours is a short program that uses
Python's standard library for the JSON and asks `openssl` for the signature. Save it as
`~/ci/oidc/mint.py`:

```schooling-example
{"language": "python", "file": "mint.py", "parts": [{"code": "\"\"\"The CI server's identity tokens. For the branch a run is building, a JSON\nWeb Token that says which repository and which branch it is, signed with\nthe CI server's own private key. Anybody holding the public half can check\nthat this server said it and that nobody changed a word since.\n\n    python3 ~/ci/oidc/mint.py REF [AUDIENCE]\n\nprints the token, which is good for five minutes. The audience is the one\nservice it is meant for; Vault, unless you say otherwise.\n\"\"\"", "note": "What the program is for, and how the CI server calls it: with the branch a run builds, as Git names it, `refs/heads/main`."}, {"code": "import base64\nimport json\nimport os\nimport subprocess\nimport sys\nimport time\nimport uuid\nfrom pathlib import Path\n", "note": "The standard library and nothing else. The signature itself is made by `openssl`, which every Linux and macOS machine already has; Python's standard library has no RSA."}, {"code": "KEY = Path(os.environ.get(\"CI_OIDC_KEY\", Path.home() / \"ci/oidc/ci-oidc.key\"))\nISSUER = \"https://ci.linkbox.example\"\nREPOSITORY = \"ana/linkbox\"\nLIFETIME = 300\n\n", "note": "The private key is the CI server's, beside this program; `CI_OIDC_KEY` points somewhere else, which the lesson uses once to see a stranger's key refused. The issuer is the name the CI signs as, and Vault will accept tokens from that name only."}, {"code": "def b64(data):\n    return base64.urlsafe_b64encode(data).rstrip(b\"=\").decode()\n\n", "note": "A JWT is three pieces of base64url, the URL-safe alphabet with the `=` padding taken off."}, {"code": "def claims(ref, audience):\n    now = int(time.time())\n    return {\n        \"iss\": ISSUER,\n        \"sub\": f\"repo:{REPOSITORY}:ref:{ref}\",\n        \"aud\": audience,\n        \"repository\": REPOSITORY,\n        \"ref\": ref,\n        \"iat\": now,\n        \"nbf\": now,\n        \"exp\": now + LIFETIME,\n        \"jti\": str(uuid.uuid4()),\n    }\n\n", "note": "The claims are the statements the token makes. `iss`, `sub`, `aud`, `iat`, `nbf`, `exp` and `jti` are the standard ones: who said it, about whom, for whom, when, and a unique id. `repository` and `ref` are this CI's own, the same names GitHub Actions uses. The token is dead five minutes after it is made."}, {"code": "def mint(ref, audience=\"vault\"):\n    header = b64(json.dumps({\"alg\": \"RS256\", \"typ\": \"JWT\"}).encode())\n    payload = b64(json.dumps(claims(ref, audience)).encode())\n    signed = header + \".\" + payload\n    signature = subprocess.run([\"openssl\", \"dgst\", \"-sha256\", \"-sign\", str(KEY)],\n                               input=signed.encode(), capture_output=True, check=True).stdout\n    return signed + \".\" + b64(signature)\n", "note": "The header says how it is signed. Header and claims are joined with a dot, and that string is what `openssl` signs with the private key: change one character of either and the signature no longer matches."}, {"code": "\nif __name__ == \"__main__\":\n    print(mint(*sys.argv[1:3]))"}]}
```

The directory now holds the CI server's whole identity, and `genpkey` made the private key readable
by its owner alone:

@@CAPTURE files@@

The claims are the interesting part of the program. `sub`, the subject, follows the same pattern GitHub Actions uses,
`repo:OWNER/REPO:ref:REF`, so the habits you build here carry over. `repository` and `ref` repeat
two parts of the subject as separate claims, which is what lets a policy check each one exactly
instead of matching a pattern in a longer string.

### A token, taken apart

Mint one for `main` and look at it. A JWT is three base64url pieces joined by dots: the header, the
claims and the signature. The first 64 characters are the whole header and the start of the claims:

@@CAPTURE mint@@

The second command decodes the middle piece. `jq` translates base64url's two URL-safe characters
back to standard base64, decodes it and parses the JSON. **Anybody holding the token can do the
same**, which is the first thing to understand about a JWT: base64 is an encoding, not encryption.
The claims are public to whoever sees the token, so they carry identities and never secrets.

What makes the claims believable is the third piece. The signature covers the first two exactly,
byte for byte. Change `refs/heads/try-something` to `refs/heads/main` in a token and the signature
no longer matches what was signed, so a verifier refuses it. **The claims are true because the
signature holds, not because they look right.**

Reading the claims from the top:

| claim | meaning | what a verifier does with it |
|---|---|---|
| `iss` | the issuer, the CI server's name | accepts tokens from one issuer only |
| `sub` | the subject: this repository, this branch | records it as who logged in |
| `aud` | the audience, the one service the token is for | refuses a token meant for another service |
| `repository`, `ref` | the CI's own claims | compares them with what a role allows |
| `iat`, `nbf`, `exp` | issued at, not before, expires, in seconds since 1970 | refuses a token outside that window |
| `jti` | a unique id for this token | lets a verifier that keeps a list refuse one used twice |

`exp` minus `iat` is 300, the five minutes `mint.py` gives every token. That is short enough that a
token leaked into a log is dead before most people would read the log, and long enough for a job to
start, log in and fetch what it needs.

### What the hosted services do differently

The exchange is the same everywhere; the plumbing around it differs in two ways, and the last
section of this lesson returns to both. First, a hosted service does not hand you its public key to
paste anywhere. It **publishes** its keys at a well-known address, and a verifier fetches them, so
the service can rotate its key without telling every customer. Second, a job has to **ask** for a
token: on GitHub Actions a workflow gets one only if its `permissions` include `id-token: write`,
so a workflow that never asked cannot be tricked into presenting one.

Your CI server has neither. Vault will be given the public key directly, and the token is minted by
hand in this lesson, playing the part the CI server would play for each run. The next section
teaches Vault to check these tokens and shows which ones it refuses.
