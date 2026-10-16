---
title: Limits beyond the request count
version: 1
---

**Counting requests limits how often a client asks, and says nothing about how much one request
asks for.** A client within its ten a second can still send one request that uploads a gigabyte,
asks for every row in a table, or nests a query twenty levels deep. OWASP's API4:2023 lists these
beside the request rate for that reason: each one is a way to spend the server's resources that a
rate limit never sees.

The rule behind every row of this table is the same. **Every quantity a client controls gets a
ceiling, and the ceiling is checked before the work is done**, not after the server has read the
gigabyte or run the query.

| what the client controls | the limit | answered with | where in this course |
|---|---|---|---|
| the size of the body | a maximum `Content-Length`, checked before reading the body | `413 Content Too Large` | here, and at the proxy in `servers-cache` |
| how many items one page returns | a default page size, and a maximum the client cannot raise | the page it asked for, capped, or `400` | lesson 2 |
| how much one query asks for | a maximum depth or a computed cost per query | `400`, before running it | lesson 3 |
| how many operations one request carries | a maximum batch size | `400` or `413` | lesson 3 |
| how long a request runs | a timeout on the work, and on the database query | `503` or `504` | `servers-cache` |
| login attempts | a few per minute per account and per address, then a delay | `429` | lesson 10 |
| money spent downstream | a spending limit at the provider, and a quota per client here | `429`, or the feature switched off | this lesson's quotas |

## Two of them, closer

### The body

`rest.py` reads `Content-Length` bytes because the client said there were that many.
A server that trusts the number reads whatever it is told, into memory. The defence is a ceiling
compared with the header before a single byte of the body is read, and a `413` when it is over.

### Login attempts

A login form is the one place where a fast client is almost always an
attacker, because people type passwords slowly. The limit there is small, five or ten a minute,
counted **per account being logged into** as well as per address, so that guesses spread across
many addresses still meet one counter. Lesson 10 is about making each guess expensive with a slow
hash; the limit is about making there be few of them. Both are needed, because each alone leaves a
gap: a slow hash with no limit can still be guessed at slowly from a thousand machines, and a limit
over a fast hash is undone by the first leak of the database.

