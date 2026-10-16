---
title: One at a time, or all at once
version: 1
---

The first two lines of `compare.py` measured something else as well. Asked one subscriber per request,
the server took about 12 milliseconds each, most of a minute for the month. Asked the whole month in
one call, the same model took 32 milliseconds for all 4,540. **Per subscriber, the batch was well over a
thousand times faster.** The model is not slower in the server. Almost all of those 12 milliseconds are
the road: opening a connection, encoding JSON, checking it, building a table of one row, and doing the
whole journey back.

That gives the two ways a model is usually put to work:

| | **online** | **batch** |
|---|---|---|
| asked | when something happens, one case at a time | on a schedule, every case at once |
| answers | in milliseconds, while somebody waits | in a file or a table, before anybody needs it |
| fits | a decision made at the moment: a checkout, a call that has just come in | a decision made for everybody: who gets a credit this month |
| here | `app.py` | `score_2026.py` from lesson 15 |

**Feira em Casa's credit is a batch decision.** It is made once a month, from a snapshot taken on the
first, for every subscriber. Scoring the month in one call, writing the chances to a file and letting the
retention team work through the list is simpler, cheaper and easier to check than 4,540 requests. The
API earns its place where the decision cannot wait for the first of the month: the support agent on the
phone with a subscriber who has just complained, asking whether this is somebody to offer the credit to
now.

Most businesses end up with both, and that is the strongest argument for this lesson's arrangement: **one
saved model, loaded by both roads**, with `compare.py` keeping them honest. Lesson 22 takes the batch
road and stays on it for three months.
