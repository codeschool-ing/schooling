---
title: Context decides
version: 1
---

The same event means different things in different places. A failed login on a test machine at noon is
noise; the same line on the server that holds the payroll, at three in the morning, from a country the
company does no business in, is not. **What turns an alert into a decision is context**, and four kinds of
it come up every time:

| context | the question it answers | where it comes from |
|---|---|---|
| **the asset** | how important is this machine, and what data does it hold? | an asset inventory with an owner per host |
| **the identity** | who is this account, what do they normally do, are they travelling? | the directory, HR, the person's manager |
| **the history** | has this address, account or host done this before? | the SIEM itself, over weeks |
| **the outside** | is this address or file known elsewhere? | threat intelligence, lesson 8 |

The history is the one an analyst can always check alone, and the one most often skipped. A small script
makes it one command. Save this in `~/week` as `context.sh`:

```bash
#!/bin/bash
# context.sh ADDRESS: what the week knows about one address, one row per day and kind
sqlite3 -header -column siem.db "SELECT date(timestamp, '-3 hours') AS day, product,
  action, group_concat(DISTINCT user) AS accounts, count(*) AS n
  FROM logs WHERE src_ip = '$1' GROUP BY day, product, action"
```

It answers, per day, *what did this address do, to which accounts, and how many times*. The next section
uses it on the alerts.

Two warnings about context. It can be **out of date**: an asset list that still says a server is a test box
after it became production will lower the priority of exactly the alert that mattered. And it can be
**asked for and not given**: "is bruno travelling?" is a question to a person, and the triage note should
say that it was asked, of whom, and when, so the next analyst does not ask again.
