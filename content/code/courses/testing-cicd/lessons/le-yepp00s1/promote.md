---
title: Promotion is a rule too
version: 1
---

The same script, the same criteria, with 1.6.1 on green:

```
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.1
ana@laptop:~/shipquote$ python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"
canary at   5%: green 0/21 = 0.0%, blue 0/379 = 0.0%
        21 answers is too few to judge; carrying on
canary at  25%: green 0/98 = 0.0%, blue 0/302 = 0.0%
canary at  50%: green 0/209 = 0.0%, blue 0/191 = 0.0%
canary at 100%: green 0/400 = 0.0%, blue 0/0 = 0.0%
promote: green takes all traffic
exit 0
ana@laptop:~/shipquote$ cat ~/envs/routes.json; echo
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 0, "green": 100}}
```

Four steps, 728 requests on green, no errors, and the weights end at 0 and 100: green has every
customer. Exit 0 tells the pipeline it may continue.

## What "promote" should mean

A clean canary is evidence that the new release is **not worse than the old one, at the things that
were measured, for the traffic that came**. It is not evidence that the release is correct. Three
consequences follow:

- **What was not measured was not checked.** This canary counted errors. A release that answered
  every request with a 200 and a wrong price would have been promoted just the same. If the business
  metric matters, it belongs in the criteria.
- **Blue is not thrown away at promotion.** It stays, idle and ready, until green has served long
  enough for slow problems to appear: a leak, a nightly job, the first Monday morning. Then the next
  release goes to blue, as lesson 10 described.
- **Every promotion is recorded**: which version, when, the numbers it passed with. When something
  surfaces two days later, the first question is what changed, and the record answers it.

The same reasoning applies to the end of a feature flag's rollout: reaching 100% is a decision with
criteria of its own, and the flag's removal date starts from there.
