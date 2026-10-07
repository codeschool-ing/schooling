---
title: How long is too long
version: 1
---

The lifetime of a copy is the longest time anybody can see a value that is no longer true. So the first
tool against stale data is not a mechanism at all: **choose each lifetime by asking how long a wrong
answer may live, not how long the server would like a rest.**

| what | how long may it be wrong | a reasonable lifetime |
|---|---|---|
| a stylesheet with its hash in the name | never; a change is a new URL | a year, `immutable` |
| the logo, the fonts | until the next deploy | a day, with validation |
| a book's description | an hour costs nothing | an hour |
| the catalogue listing, prices included | a minute is a nuisance | a minute |
| stock left, "only 2 in stock" | seconds; oversell is real | not cached in a shared cache, or seconds |
| the basket, the order, the payment | never | `no-store` |

Two consequences are worth stating plainly.

**A short lifetime is not free.** At one second, the cache spares the application only the requests
that arrive within the same second, and lesson 5 showed that the hit ratio falls apart when the lifetime
is shorter than the gap between requests. Every lifetime is a trade between the load on the application
and the age of what people see.

**A long lifetime needs a way out.** If a description is cached for an hour and somebody notices a typo
in it, waiting an hour is silly. Every long lifetime should come with a way to replace the copy now, and
the next two sections are the two ways Nginx gives you. The section after them removes the problem for
static files altogether, by never changing a URL's content at all.
