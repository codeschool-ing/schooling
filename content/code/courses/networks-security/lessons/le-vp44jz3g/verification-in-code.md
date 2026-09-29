---
title: Verification in code, and where it gets switched off
version: 1
---

Libraries verify by default, and that default is worth confirming rather than assuming. A small
Python client that fetches the shop with the standard library's default context:

```schooling-example
{"language": "python", "file": "fetch.py", "parts": [{"code": "import ssl, urllib.request\n\nurl = \"https://www.example.com/\"\nctx = ssl.create_default_context()", "note": "`create_default_context()` is the right way to get TLS in Python: it loads the system's trust store, requires a valid certificate and checks the name."}, {"code": "print(\"verify:\", ctx.verify_mode.name, \"| check_hostname:\", ctx.check_hostname)", "note": "Print the two settings that matter, so the default is seen rather than believed."}, {"code": "print(urllib.request.urlopen(url, context=ctx).read().decode().strip())", "note": "Fetch the page through that context. Against the impostor of the previous section, this line would fail with `SSLCertVerificationError` and never send the request."}], "output": "verify: CERT_REQUIRED | check_hostname: True\norders service: ok"}
```

As it ran on `laptop`, against the real shop:

```
ana@laptop:~$ python3 fetch.py
verify: CERT_REQUIRED | check_hostname: True
orders service: ok
```

`CERT_REQUIRED` and `check_hostname: True`: both halves of the check, the chain and the name.

**Verification gets switched off in code by somebody fixing an error**, almost always in good faith:
a test server with a self-signed certificate, an internal service before the company had a CA, a
proxy that broke TLS. The switch then survives into production. Every language has its own spelling,
which makes them easy to search for:

| where | what turns verification off |
|---|---|
| Python `requests` | `verify=False` |
| Python `ssl` | `CERT_NONE`, `check_hostname = False`, `_create_unverified_context()` |
| `curl` in scripts | `-k`, `--insecure` |
| Go | `InsecureSkipVerify: true` |
| Node.js | `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0` |

A search over a code base for those spellings is one line, and worth running in every review and in
continuous integration. On `laptop`'s home directory it finds nothing:

```
ana@laptop:~$ grep -rnE "verify=False|CERT_NONE|_create_unverified_context|curl -k|--insecure|InsecureSkipVerify" --include=*.py --include=*.sh --include=*.go . 2>/dev/null; echo "matches: $?"
matches: 1
```

`grep` exits with 1 when nothing matched. **Every hit, in a real code base, is a question to ask**:
which connection does this protect, and what would a fake certificate do there?
