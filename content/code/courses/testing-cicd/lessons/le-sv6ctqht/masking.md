---
title: Masking in logs, and its limits
version: 1
---

CI services try to keep secrets out of logs by **masking**: before a line of a job's output is stored,
every occurrence of a registered secret's value is replaced with asterisks. It is a useful safety net,
and it works by exact match, which is both why it works and where it stops.

Here the lab plays the masker's part with `sed`, replacing the token's exact value, and a careless
debug line plays the job's output:

```
ana@laptop:~/shipquote$ printf 'Authorization: Bearer lab-live-token\n' | sed 's/lab-live-token/***/g'
Authorization: Bearer ***
ana@laptop:~/shipquote$ printf 'Bearer lab-live-token' | base64 | sed 's/lab-live-token/***/g'
QmVhcmVyIGxhYi1saXZlLXRva2Vu
ana@laptop:~/shipquote$ printf 'Bearer lab-live-token' | base64 | base64 -d; echo
Bearer lab-live-token
```

The first line is masked: the value appeared as written, so it was found and replaced. The second
line is the same header **encoded in base64**, as plenty of tools do with credentials, and it went
through untouched, because the bytes `lab-live-token` do not appear in it. The third line shows what
anybody reading that log can do with it: decode it, and there is the token.

GitHub documents exactly this limit: masking matches the secret's value as registered, and a value
that has been transformed, encoded, split across lines or partly printed is not masked. The same is
true of GitLab's masked variables. **Masking is the net under the trapeze, not the act.**

## Not printing it at all

The defence that holds is a program that never prints its secrets. After a quote through the carrier
in production, the log was searched for the token:

```
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
ana@laptop:~/shipquote$ grep -c lab-live-token ~/envs/production/app.log
0
ana@laptop:~/shipquote$ tail -2 ~/envs/production/app.log
GET /version 200 0.1ms v=1.5.0
GET /quote?cep=01310-100&weight=1200&subtotal=5000 200 38.1ms v=1.5.0
```

**Zero lines contain it.** The request log records the method, the path, the status, the time and the
version, and nothing from the headers; the carrier client sends the token in a header and never
writes it anywhere. When the carrier fails, the line `price` logs carries the error's message, which
section 10 shows, and an HTTP error message does not include the request's headers.

Three habits keep it that way:

- **Log what the program decided, not what it was given.** "Carrier unavailable, using the table"
  helps whoever is on call; a dump of the request object helps whoever reads the log next.
- **Never turn on debug output that prints headers or environment in a shared environment.**
  `set -x` in a shell step prints every command with its expanded variables; a framework's request
  debugging prints `Authorization` headers.
- **Search for leaks on purpose.** The `grep -c` above, run against logs and artifacts, is a test like
  any other, and it can run in the pipeline.
