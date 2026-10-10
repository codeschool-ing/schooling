---
title: Who the client is
version: 1
---

**A limit per client needs an answer to "which client is this?", and the answer is the key the
limit is stored under.** There are three usual candidates, and they are not equally good:

| key | where it comes from | what goes wrong |
|---|---|---|
| **API key** | a header the client sends on every request | nothing, as long as keys are issued per client and kept secret |
| **account** | the user a session or a token belongs to (lessons 8 and 9) | nothing, once the request is authenticated; before that there is none |
| **IP address** | the connection the request arrived on | many people share one, one person can have many, and the header that carries it can be typed by anybody |

This lesson's limiter uses an **API key**, sent as `X-API-Key`. It is the simplest thing that
names a client rather than a machine, and a key belongs to somebody who signed up for it, so the
limit can differ by what they signed up for. How a key is issued and stored is lesson 7; here three
fixed demo keys are written into the program.

## Why the address is the weak one

It looks free: every request arrives from an address, and no client has to do anything. It names
the wrong thing in both directions.

**Many clients behind one address.** An office, a university or a mobile carrier puts hundreds or
thousands of people behind a few public IPv4 addresses with NAT. A limit per address treats the
whole office as one client, and the colleague who runs a script gets everybody else refused.

**One client behind many addresses.** A single IPv6 customer is usually handed a `/64`, which is
more addresses than the whole IPv4 internet has, and a client that wants a fresh address for each
request can have one. A limit per address stops nobody who is trying.

**And the address you read may not be the client's.** When a proxy or a load balancer sits in
front of the API, every connection arrives from the proxy, and the client's address travels in a
header, usually `X-Forwarded-For`. A header is text the client can write. Against lesson 1's
`rest.py`, with `-v` so curl shows what it sent and what came back:

```
ana@api:~/shelf$ curl -sv -H 'X-Forwarded-For: 203.0.113.7' localhost:8000/v1/books/1 2>&1 | grep -E '^[<>] (GET|X-Forwarded|HTTP)'
> GET /v1/books/1 HTTP/1.1
> X-Forwarded-For: 203.0.113.7
< HTTP/1.1 200 OK
```

curl put the header in because it was told to, with an address from a range reserved for
documentation, and the server accepted the request as it would any other. The second terminal
shows where the request really came from:

```
127.0.0.1 - - [10/Oct/2026 01:30:11] "GET /v1/books/1 HTTP/1.1" 200 -
```

**`X-Forwarded-For` is only trustworthy when your own proxy wrote it**: the proxy overwrites or
appends to it, and the application reads only the part the proxy added and ignores the rest. An
application that reads the header directly, with no proxy of its own in front, is limiting by
whatever the client chose to type. Setting that up properly belongs to the proxy, and
`servers-cache`, the course after this one, is where proxies are built.

## Where the address is still all you have

Some requests come before any key or account exists: the sign-up form, the login form, the
"forgot my password" form. There the address, with all its faults, is the only thing to count, and
it is usually combined with a count per **target**: per e-mail address being logged into, so that
a thousand addresses guessing one person's password are still one counter. Lesson 10 is about the
password itself, and the last section of this lesson comes back to login attempts.

`limits.py` answers a request with no valid key with `401` and counts nothing, to keep the program
short. In front of a real API those requests are limited too, by address, for the reason above:
a flood of requests with no key is still a flood.
