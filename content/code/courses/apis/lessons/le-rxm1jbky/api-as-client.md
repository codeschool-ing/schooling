---
title: When the API is the client
version: 1
---

**Every lesson of this course so far has defended an API against the requests it receives. API7 and
API10 are about the requests it sends.** An API that fetches a book cover from a URL, calls a payment
provider or reads exchange rates from somebody else is a client, and a client has its own two ways to
go wrong: going where it should not, and believing what it is told.

## API7: server-side request forgery

Suppose shelf let a client attach a cover to a book by sending the image's address, and the server
downloaded it. The feature looks harmless because the client could have downloaded the image itself.
**The difference is where the request comes from.** The server sits inside a network the client
cannot see. From there it reaches its own `127.0.0.1`, the database, other internal services, and in
most clouds a metadata service at `169.254.169.254`, which hands the machine's own credentials to
anything that asks from inside. An address the client chooses, fetched by the server, is a request made with
the server's position and the server's trust. That is server-side request forgery, SSRF.

The defence starts with not offering the feature in its open form. A cover can be uploaded as bytes
instead of fetched from an address, and a partner's service can be a name in the configuration
rather than something a request supplies. Where the API really must fetch an address it was given:

- an allowlist of destinations, the hosts it is meant to talk to, compared exactly, as
  `ORIGINS` is in `secure.py`, with `https` as the only scheme;
- the address checked, not the name: resolve the name, refuse anything that is not a public
  address, and connect to the address that was checked, so a name that resolves differently the
  second time gains nothing;
- no redirects followed without checking the new destination the same way, since a redirect is a
  second address the client chose;
- a timeout and a size limit on what comes back, and the response never passed through to the
  client whole.

Python's standard library already knows which addresses are public. Of five addresses, only the
first is one an API should ever fetch on a client's behalf:

```
ana@api:~/shelf$ for a in 1.1.1.1 127.0.0.1 10.0.0.7 169.254.169.254 ::1; do python3 -c "import ipaddress, sys; a = sys.argv[1]; print(a, ipaddress.ip_address(a).is_global)" $a; done
1.1.1.1 True
127.0.0.1 False
10.0.0.7 False
169.254.169.254 False
::1 False
```

Loopback, a private network and the link-local range where cloud metadata lives are all
`False`. A check built on that, with the allowlist in front of it, refuses each of them before a
connection is opened.

## API10: unsafe consumption of APIs

The second way is trusting. A partner's API answers, and its answer goes into the database, onto a
page, into the next request, with less checking than a user's input would get, because the partner
is a company with a contract. The partner can be compromised, can change its format without notice,
or can simply have a bug, and **whatever it sends then enters your system with your API's
authority.**

The defences are the ones this course applies to its own clients, turned around:

- validate the answer against a schema, with the same tools lesson 2 uses for requests, and
  refuse what does not match rather than storing part of it;
- keep TLS verification on, always, as the HTTPS section says; a client that skips it will
  talk to anybody who answers;
- set a timeout and a size limit, so a slow or enormous answer from a partner cannot hold your
  API's threads;
- treat its text as untrusted wherever it is shown or stored, exactly as if a stranger had typed
  it;
- do not follow its redirects blindly, for the reason given under API7.

The two risks are the same mistake in two directions: an API that is careful about the requests it
receives, and careless about the requests it makes.
