---
title: Saying nothing, and logging it
version: 1
---

**A refusal should tell the caller that they are refused, and nothing else.** The tempting refusal
is the helpful one: "no user called nobody", "wrong password for ana". Together those two messages
answer a question nobody should be able to ask an API, whether a particular person has an account
here, and on a bookshop that is a small leak, while on a clinic or a dating site it is the whole of the
damage.

`keys.py` answers both cases with the same words and the same code, on a fresh server again:

```
ana@api:~/shelf$ curl -s -u ana:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
{"error": "authentication required"}
401 0.073168s
ana@api:~/shelf$ curl -s -u nobody:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
{"error": "authentication required"}
401 0.067445s
```

**The words are the easy half; the time is the other half.** A server that looks the user up, finds
nobody and refuses at once answers an unknown name in a fraction of the time it takes to run scrypt
on a known one, and a stopwatch reads that as clearly as a message. `check_password` closes it with
`DECOY`: an unknown user's password is run through scrypt against the hash of nobody's password, so
both refusals cost the same work. Above, a wrong password for ana took 0.073 seconds and the unknown
user 0.067; the right password costs the same scrypt and lands in the same range:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 -o /dev/null -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
200 0.051551s
```

The login endpoint follows the same rule, and so does a token the server has never seen:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "nobody", "password": "river-lamp-42"}'
{"error": "wrong username or password"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer not-a-token' localhost:8000/v1/whoami
{"error": "invalid or expired token"}
```

The same rule reaches past this file. A sign-up form that says "this address is already registered"
and a password reset that says "no account with that address" answer the forbidden question too, and
the usual way out is to say the same thing in both cases ("if an account exists, we have sent an
e-mail") and to tell the owner of the address, rather than the person at the keyboard.

## Logging without leaking

The refusals say nothing to the caller, and the server's own log should say a great deal to whoever
runs it. This is the second terminal for the requests above:

```
keys on http://127.0.0.1:8000
auth: basic refused user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 401 -
auth: basic refused user='nobody'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 401 -
auth: basic ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 200 -
auth: login refused user='nobody'
127.0.0.1 - - [10/Oct/2026 01:26:19] "POST /v1/login HTTP/1.1" 401 -
auth: bearer refused token=ce6f21ae
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/whoami HTTP/1.1" 401 -
```

Every decision has a line, and each line was written to be useful and harmless at once:

- a user name is logged, because "fifty refusals for ana in a minute" is the line somebody looks
  for. It is a trade-off: a person who types their password into the name field puts it in the log,
  so the log is protected like the database;
- a token is logged as a **fingerprint**, the first eight characters of its SHA-256. `ce6f21ae` is
  `not-a-token` hashed, enough to match a refusal against a row or a support ticket, and useless as a
  credential;
- a key is logged by its prefix, which is not secret and is exactly what the prefix is for.

What is never there is as important. **No password, no token, no key, and no `Authorization`
header.** Python's server logs only the request line, which is why the last section's query string
was the one way a credential got in. The usual way one gets in by accident is a line of debugging that
prints every header of a request, left in when the debugging stopped, and the rule that prevents it
is that **a log line names the credential and never contains it**.
