---
title: Why limit at all
version: 1
---

**A rate limit is a promise about how much one client may ask for, enforced by the server.** It
says, for each client, how many requests in how much time, and what happens to the one over the
line: it is refused with `429 Too Many Requests`, and the answer says when to try again.

The picture most people arrive with is a wall against attackers. That is part of it, and the
smaller part. The client that sends ten thousand requests a minute is usually somebody's own
program: a loop with the exit condition wrong, a mobile app retrying every failure at once, a
script a customer left running over the weekend. None of them means harm, and each one can take the
service down for everybody else just as well.

Nothing in `rest.py` stands in the way of any of that. A hundred requests, one after the other,
from a shell loop:

```
ana@api:~/shelf$ time (for i in $(seq 100); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/v1/books; done | sort | uniq -c)
    100 200

real	0m1.878s
user	0m0.500s
sys	0m0.422s
```

A hundred answers and a hundred `200`s. Six books is a cheap thing to read; a search over a million
rows, a PDF rendered on demand, or a text message sent through a provider who bills per message is
not, and the loop is the same three lines.

## What a limit is for

There are three reasons, and they decide different numbers:

| reason | what goes wrong without a limit | what the limit is measured in |
|---|---|---|
| **protecting the service** | one client fills the threads, the database connections or the memory, and everybody's requests slow down or fail | requests per second, and how many may run at once |
| **fairness between clients** | the client that asks fastest gets the most service, whatever it paid for | an allowance per client, not one for the whole API |
| **cost** | each request spends money: compute, egress, a paid API called behind it | a quota per day or month, often per plan |

The second row is why this lesson's limit is **per client**. A single counter for the whole API
protects the server and nothing else: once one busy client has used it up, every other client is
refused too, and the one that caused it has taken everybody down politely instead of rudely.

## OWASP's name for the missing limit

The OWASP API Security Top 10 is a list of the ways APIs actually get broken, and its 2023 edition
names this one **API4:2023, Unrestricted Resource Consumption**. Its examples go past requests per
second: no ceiling on the size of an upload, on how many records one page returns, on how many
operations one request may batch together, on the memory or the time a request may take, and no
spending limit on a third-party service the API calls for each request. The last section of this
lesson comes back to those. Lesson 13 walks through the rest of the list.

A limit does a second job that is easy to miss. **The refusal is also an instruction.** A `429`
with `Retry-After: 1` tells a well-written client exactly what to do, and the headers on every
successful answer tell it how close it is to the line before it gets there. That turns the limit
from a wall clients bounce off into a speed clients can keep to.
