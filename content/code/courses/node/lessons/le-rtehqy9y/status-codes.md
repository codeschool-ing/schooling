---
title: Choosing a status code
version: 1
---

**A status code is the first thing a client reads, and often the only thing a program reads.** The
body explains; the code decides what happens next: retry, give up, ask the user, follow a link. So
each code the links service sends is chosen to make the client's next step obvious. These are all of
them, after this lesson:

| status | when the links service sends it | what the client should do |
|---|---|---|
| 200 OK | a link, or the admin's list | use the body |
| 201 Created | a new link, with `Location` | remember the code |
| 204 No Content | a link deleted | nothing more |
| 302 Found | a short link followed | go to `Location` |
| 304 Not Modified | the client's copy is still current | use the copy it has |
| 400 Bad Request | a body, a code or a limit that could never work | fix the request; retrying is useless |
| 401 Unauthorized | the admin key is missing or wrong | send the key |
| 404 Not Found | no such link, or no such path | stop asking |
| 405 Method Not Allowed | a method the path does not have, with `Allow` | use one of those |
| 406 Not Acceptable | an `Accept` the service cannot meet | ask for JSON |
| 413 Content Too Large | a body over 1 kB | send less |
| 500 Internal Server Error | our mistake, logged | try later, or tell us |

Two lines in that table hold the distinction worth learning. **4xx means the client should change
something; 5xx means the server should.** A service that answers its own bugs with 400 tells every
client the bug is theirs, and a service that answers bad input with 500 pages somebody at night for
a typo in a request.

Some codes the service does not send are just as deliberate. There is no 422 for a body that parsed
but did not validate: 400 with a list of problems says the same thing, and many APIs use either. There
is no 429 for too many requests, because nothing here limits rates yet; a proxy in front of it can,
which the `servers-cache` course sets up. The `apis` course, two courses on, makes these choices for a
whole API, with versioning and errors in a standard shape, and this table is the first draft of that
kind of decision.
