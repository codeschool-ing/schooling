---
title: Every word after the cookie's value
version: 1
---

**A `Set-Cookie` header is a name, a value, and a list of instructions to the browser about who may
read the cookie, where to send it and for how long.** The planner's server wrote
`sid=…; HttpOnly; SameSite=Lax; Path=/` in lesson 5. Here is each attribute that matters for a session,
including the three it left out.

| attribute | what it tells the browser | for a session cookie |
|---|---|---|
| `HttpOnly` | no script may read this cookie through `document.cookie` | always |
| `Secure` | send it only over HTTPS; `localhost` counts as secure, so development works | always |
| `SameSite=Lax` | leave it off requests another site starts, except plain links the person follows | the default to choose |
| `SameSite=Strict` | leave it off every request another site starts, links included | where arriving signed in from a link does not matter |
| `SameSite=None` | send it everywhere; only allowed with `Secure` | only for a cookie meant to work inside other sites |
| `Path=/` | send it with every address of the site | yes |
| `Max-Age=28800` | forget it after that many seconds, here eight hours | yes, as long as the server's own limit |
| `Domain=…` | send it to subdomains as well | leave it out, so the cookie stays with the one host that set it |

## The `__Host-` prefix

A cookie whose name begins with `__Host-` is one the browser **refuses to accept** unless it is
`Secure`, has `Path=/` and has no `Domain`. That sounds like a restriction and it is a guarantee: a
cookie called `__Host-sid` can only have been set by this exact host, over a secure connection, so
neither a careless subdomain nor a page served over plain HTTP can plant a session cookie of its own
for the browser to send. Renaming the cookie costs nothing and turns three rules into one that the
browser enforces.

## What none of them does

Every attribute here is an instruction to the browser, and **the server has to keep its own rules as
well**. `Max-Age` makes the browser drop the cookie; it does not stop a copy of the value from working,
if the server still accepts it. Signing out clears the cookie; whether the login behind it ends is the
server's decision. The next section writes the three tests that ask the server, rather than the
browser, and all three of them fail.
