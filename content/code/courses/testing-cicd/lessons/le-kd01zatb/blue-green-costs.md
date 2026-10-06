---
title: The way back, and what it costs
version: 1
---

The reason to keep blue running is the next command. Going back is the same edit, in the other
direction:

```
ana@laptop:~/shipquote$ time sed -i 's/"blue": 0, "green": 100/"blue": 100, "green": 0/' ~/envs/routes.json

real	0m0.004s
user	0m0.000s
sys	0m0.003s
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ grep -c "^error" ~/envs/production-green/app.log; grep "^error" ~/envs/production-green/app.log | sort | uniq -c
77
     77 error: KeyError: 57
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8302/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"error": "internal error"}
```

Three milliseconds, and customers are on 1.5.0 again. No build, no deploy, no process started: blue
never stopped. That speed is what blue-green sells, and it is why the error above was a short
incident rather than a long one.

The last two commands show why it happened. Green's log has 77 lines, all the same, `KeyError: 57`,
and asking green directly for a quote to Alagoas reproduces it. Green is still there to be
examined, out of traffic. Lesson 11 follows that error to its fix.

## What blue-green costs

- **Twice the production.** Two full copies run all the time, or at least for the length of every
  release. For one small process that is nothing; for a fleet it is a real bill. Some teams create
  green for the release and remove it once blue is retired.
- **One database.** Both sides usually share it, because copying production's data at every release
  is not practical. Green's schema changes are therefore live for blue too, so the rule of the
  rolling update still holds: the new release has to work with data the old one wrote, and the old
  one with data the new one writes, for as long as switching back is possible.
- **Everything at once.** The switch moves every customer in one step. Blue-green made the way back
  fast; it did nothing to make the way forward small. The bug above reached every customer for the
  second before somebody noticed.
- **State in the process.** A request in progress on blue when the weights move finishes there;
  a customer with a session held in blue's memory loses it. Sessions belong in a store both sides
  can read.

## After the switch

Once green has served long enough to be trusted, blue is the idle side, and the next release goes to
blue. The colours never mean "old" and "new"; they name two places, and the release alternates
between them.
