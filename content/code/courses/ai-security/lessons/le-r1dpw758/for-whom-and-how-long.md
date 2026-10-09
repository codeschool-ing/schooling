---
title: One file per client, and a date on every line
version: 1
---

Every memory has two properties the code sets and the model never touches: **whose it is**, and
**until when it may be used**.

## Whose

The store is one file per account, `data/memory/ACCOUNT.jsonl`, and the assistant answering a client
reads that client's file and no other:

```
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-03-21
ac-7Q2M on 2026-03-21, memories in use: 4
  m1  job        until 2026-05-31  4471
  m2  preference until 2027-03-02  dark blue logo color
  m3  job        until 2026-06-07  always pays by Pix
  m4  preference until 2027-03-20  weekly updates preferred
ana@lab:~/guard$ guard memory show --as ac-0Z5Q --now 2026-03-21
ac-0Z5Q on 2026-03-21, memories in use: 0
```

`ac-0Z5Q` has nothing, because nothing in the store is theirs. That sounds obvious and is the rule
most often broken by accident: a memory kept in one shared table and looked up by similarity, the way
lesson 15's search worked before it had `--as`, will one day hand one client's preference to
another. **The account comes from the session, as in lesson 15**, and the store is partitioned by it
before anything is looked up.

## How long

Each line carries `until`, computed from the kind: a preference is kept a year, a fact about a job
ninety days, because a job ends and a preference usually outlives one. On 1 July the job memories of
March are past their date:

```
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-07-01
ac-7Q2M on 2026-07-01, memories in use: 2
  m2  preference until 2027-03-02  dark blue logo color
  m4  preference until 2027-03-20  weekly updates preferred
ana@lab:~/guard$ wc -l < data/memory/ac-7Q2M.jsonl
4
ana@lab:~/guard$ guard memory sweep --now 2026-07-01
ac-7Q2M: 2 deleted, 2 kept
ana@lab:~/guard$ wc -l < data/memory/ac-7Q2M.jsonl
2
```

The order of those four commands is the point. `show` stopped using the two expired memories, and the
file still held all four lines. **A memory the assistant no longer uses is still personal data Tarefa
holds**, and the LGPD's question in lesson 12 is about what is held, not about what is used. `sweep`
deleted the two, and the file went from four lines to two. In production the sweep runs every day, as
the log sweep of lesson 11 does.

Retention by kind is a decision with no single right number, and a team writes down why it chose the
one it did. What is not a decision is the existence of a limit: **a memory with no expiry date is
kept for ever by default**, which nobody chose.
