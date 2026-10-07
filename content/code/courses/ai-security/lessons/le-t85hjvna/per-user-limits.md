---
title: A limit per user, so that one person cannot spend everybody's
version: 2
---

A provider limits each key: so many requests a minute, so many tokens a minute, so much a month.
Those limits protect the provider. **They do nothing to protect Tarefa's users from each other**,
because a key's budget is shared by everybody who uses it, and one person with a script can spend it
for all of them.

`data/api-requests.jsonl` is five minutes of the assistant's traffic, written by the course: six
users, each request tagged with an end-user identifier like the ones in the previous section, all on
Tarefa's one key. During the second and third minutes, one of the six runs a script. This program
writes it from a table of how many requests each user sent in each minute. Save it as
`~/guard/tools/traffic.py`:

```python
# traffic.py: write five minutes of the assistant's API requests, one per line.
#
#   guard traffic > FILE
#
# WRITTEN BY THE COURSE from the table below: six of Tarefa's users, each
# tagged with an end-user id, all on Tarefa's one key with the provider. One
# of the six runs a script in the second and third minutes. Times are seconds
# after the first request, so a replay gives the same answer every time.
import json

USERS = {  # end user: requests in each of the five minutes
    "eu-2b8e41c07d93a5f60e1c": [3, 4, 3, 5, 4],
    "eu-5c0d9f72aa1e48b3c6d2": [6, 5, 6, 4, 6],
    "eu-7e3a18b5c90f2d64a1b7": [2, 2, 3, 2, 2],
    "eu-91f4d2a6e07c3b85d1e9": [4, 6, 5, 6, 5],
    "eu-b37c05e8d1a294f6c0a3": [5, 3, 4, 4, 3],
    "eu-e60a7d3c4b19f8e25d07": [2, 90, 110, 3, 2],
}

rows = []
for user, per_minute in USERS.items():
    shift = sum(map(ord, user)) % 7  # so that the six do not all arrive at once
    for minute, n in enumerate(per_minute):
        for i in range(n):
            t = minute * 60 + (i * 60) // n + shift
            rows.append({"t": min(t, minute * 60 + 59), "key": "tarefa-prod", "end_user": user})
rows.sort(key=lambda r: (r["t"], r["end_user"]))
for r in rows:
    print(json.dumps(r))
```

And the replay, `~/guard/tools/ratelimit.py`:

```python
# ratelimit.py: a log of API requests replayed against rate limits.
#
#   guard ratelimit FILE --per-key N [--per-user M]
#
# A limit is a sliding window: a request is allowed if fewer than the limit
# were allowed in the 60 seconds before it. A refused request does not count
# against the window, as a client that is refused and waits gets back in.
# With --per-user, each end user has a window of their own in front of the key.
import argparse
import json
from collections import deque


class Window:
    def __init__(self, limit):
        self.limit, self.times = limit, deque()

    def allow(self, t):
        while self.times and self.times[0] <= t - 60:
            self.times.popleft()
        if len(self.times) < self.limit:
            self.times.append(t)
            return True
        return False


p = argparse.ArgumentParser(prog="guard ratelimit")
p.add_argument("file")
p.add_argument("--per-key", type=int, required=True)
p.add_argument("--per-user", type=int)
a = p.parse_args()

with open(a.file) as f:
    rows = [json.loads(line) for line in f if line.strip()]
keys, users, out = {}, {}, {}
for r in rows:
    stat = out.setdefault(r["end_user"], [0, 0])
    stat[0] += 1
    uw = users.setdefault(r["end_user"], Window(a.per_user)) if a.per_user else None
    if uw and not uw.allow(r["t"]):
        continue
    if not keys.setdefault(r["key"], Window(a.per_key)).allow(r["t"]):
        if uw:
            uw.times.pop()  # the user's slot is given back: the key refused it
        continue
    stat[1] += 1

print("limits: %d a minute per key%s" % (
    a.per_key, ", %d a minute per user" % a.per_user if a.per_user else ""))
print("%-25s %5s %8s %8s" % ("end user", "sent", "allowed", "refused"))
for user in sorted(out):
    sent, allowed = out[user]
    print("%-25s %5d %8d %8d" % (user, sent, allowed, sent - allowed))
hit = [u for u, (s, al) in out.items() if s > al]
print("%d of %d users had a request refused" % (len(hit), len(out)))
```

```
ana@lab:~/guard$ guard traffic > data/api-requests.jsonl
ana@lab:~/guard$ head -3 data/api-requests.jsonl
{"t": 0, "key": "tarefa-prod", "end_user": "eu-b37c05e8d1a294f6c0a3"}
{"t": 2, "key": "tarefa-prod", "end_user": "eu-2b8e41c07d93a5f60e1c"}
{"t": 2, "key": "tarefa-prod", "end_user": "eu-5c0d9f72aa1e48b3c6d2"}
ana@lab:~/guard$ guard ratelimit data/api-requests.jsonl --per-key 60
limits: 60 a minute per key
end user                   sent  allowed  refused
eu-2b8e41c07d93a5f60e1c      19       18        1
eu-5c0d9f72aa1e48b3c6d2      27       26        1
eu-7e3a18b5c90f2d64a1b7      11       10        1
eu-91f4d2a6e07c3b85d1e9      26       21        5
eu-b37c05e8d1a294f6c0a3      19       16        3
eu-e60a7d3c4b19f8e25d07     207       97      110
6 of 6 users had a request refused
```

Sixty a minute on the key stands for the provider's limit. Every one of the six users had requests
refused. The five who did nothing unusual lost 11 between them, and `eu-91f4d2a6e07c3b85d1e9` lost 5
of 26. The script, `eu-e60a7d3c4b19f8e25d07`, still got 97 requests through, because a shared limit
refuses whoever happens to arrive when the window is full, and the script arrives most often. For the
other five, the assistant stopped answering at odd moments during those two minutes, for no reason
they could see.

Now the same traffic with a limit per user in front of the key, which is a limit only Tarefa can
apply, because only Tarefa knows who each request is for:

```
ana@lab:~/guard$ guard ratelimit data/api-requests.jsonl --per-key 60 --per-user 20
limits: 60 a minute per key, 20 a minute per user
end user                   sent  allowed  refused
eu-2b8e41c07d93a5f60e1c      19       19        0
eu-5c0d9f72aa1e48b3c6d2      27       27        0
eu-7e3a18b5c90f2d64a1b7      11       11        0
eu-91f4d2a6e07c3b85d1e9      26       26        0
eu-b37c05e8d1a294f6c0a3      19       19        0
eu-e60a7d3c4b19f8e25d07     207       47      160
1 of 6 users had a request refused
```

The script is held to 20 a minute and gets 47 through. Nobody else loses a request, and the key's
limit is never reached. **The per-user limit is set well below the key's**, so that no single user
can use up the key's budget by themselves: 20 a minute is a third of it here.

## What else rides on the identifier

**A refusal the user can understand.** The refused request gets an HTTP 429 with a `Retry-After`
header and a message that says the limit is per person, so a legitimate user who hits it knows to
wait rather than to retry in a loop, which would only refuse them for longer.

**Cost, not only count.** One request can carry a few hundred tokens or a hundred thousand. A
request limit bounds the rate; a daily budget of tokens per user bounds the bill. Both are kept by the
same identifier, and the second is what stops a user from turning a free tier into somebody else's
batch job.

**An abuse report you can act on.** When a provider writes to say that requests tagged
`eu-e60a7d3c4b19f8e25d07` broke its policies, Tarefa has to find the account. Recomputing the
identifier for every account would work and is slow; storing the identifier beside each account, in
Tarefa's own database, makes it one indexed lookup. That table is personal data like the account it
sits in, and it is erased with it.

**One limit is never the whole defence.** A determined user opens a second account. Per-user limits
make abuse cost an account per budget, which is why lesson 8 is about who gets an account, and how
much it can do, before it has earned more.
