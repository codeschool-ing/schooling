---
title: A canary that stops itself
version: 1
---

Production is back where lesson 10 found it: blue on 1.5.0 with all the traffic, green on 1.6.0,
the release that cannot quote Alagoas. This time nobody edits the weights. `canary.py` does:

```
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8302/version; echo
{"version": "1.6.0", "env": "production-green", "carrier": "table"}
ana@laptop:~/shipquote$ python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"
canary at   5%: green 0/21 = 0.0%, blue 0/379 = 0.0%
        21 answers is too few to judge; carrying on
canary at  25%: green 2/98 = 2.0%, blue 0/302 = 0.0%
abort: green is 2.0 points worse than blue; all traffic back to blue
exit 1
ana@laptop:~/shipquote$ cat ~/envs/routes.json; echo
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}
```

At 5%, green answered 21 requests, fewer than the 50 the rule demands, so the script said so and
carried on. At 25%, green answered 98 and failed 2, while blue failed none. The gap of 2.0 points
was over the limit of 1.0, the weights went back to 100 and 0, and the script exited 1. Nobody had
to be looking. The exit code is what a pipeline reads: a release job that runs `canary.py` stops
there, red, and the next job never starts.

Two customers out of 400 at the second step met the bug. With blue-green in lesson 10, 77 did.

## Read the rule as well as its result

The rule worked here, and it has a flaw worth seeing. At 98 answers, **one** error is a rate of
1.02%, which is already more than 1.0 point above a blue with none. So between 50 and 99 answers
the rule is really "stop on the first error". Lesson 10 section 08 showed what one error is worth:
very little. A canary with this rule will sometimes abort a good release on a single unlucky request.

There are two honest fixes, and they pull in opposite directions:

- **Demand more evidence**: raise `MIN_REQUESTS` until one error cannot cross the gap alone. With a
  gap of 1 point, that means at least 100 answers. Bugs are caught later, at a bigger share.
- **Use a statistical test** rather than a fixed gap: ask whether the difference between the two
  rates is larger than chance would produce at this sample size. This is what dedicated canary
  analysis tools do.

Either is better than the third option teams drift into: rerunning an aborted canary until it
passes. Each rerun is another draw, and a release with a rare bug passes on one of them sooner
or later.
