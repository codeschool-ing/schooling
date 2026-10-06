---
title: A limit per user, so that one person cannot spend everybody's
version: 1
---

A provider limits each key: so many requests a minute, so many tokens a minute, so much a month.
Those limits protect the provider. **They do nothing to protect Tarefa's users from each other**,
because a key's budget is shared by everybody who uses it, and one person with a script can spend it
for all of them.

`data/api-requests.jsonl` is five minutes of the assistant's traffic, written by the lab: six users,
each request tagged with the end-user identifier from the previous section, all on Tarefa's one key.
During the second and third minutes, one of the six runs a script.

```
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
