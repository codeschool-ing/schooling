---
title: Kinds of flag, and the debt they leave
version: 1
---

Turning the feature off is the same edit as turning it on:

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 0}' > ~/envs/flags.json
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c3"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.6.1", "env": "production-green", "carrier": "table"}
```

`c3`, who had the estimate a moment ago, no longer has it. Production still runs 1.6.1. Nothing
was deployed or rolled back: the feature was withdrawn and the release stayed.

## Four kinds, with different lifetimes

Flags are not all the same, and treating them alike is how a codebase ends up with hundreds.

- **Release flags** hide a feature until it is ready, like `delivery_estimate`. They should live for
  days or weeks, and be removed once the feature is on for everyone.
- **Operational flags**, or kill switches, turn off something expensive or fragile under pressure:
  the carrier call, a recommendation panel. They can stay for years, and they should be tested,
  because the day they are used is a bad day.
- **Experiment flags** split customers to compare two versions of something, a price display or a
  checkout step. They live as long as the experiment, and the measurement matters more than the
  flag.
- **Permission flags** turn a feature on for some customers by right: a paid plan, a beta
  programme. These are a product rule and arguably not flags at all.

## The debt

A flag is two versions of the code in one file. Every flag doubles the number of ways the program
can behave; ten flags make 1024 combinations, and no test suite covers them all. So:

- **Each release flag gets an owner and a removal date** when it is created. A flag still at 100% a
  month later is a dead branch that somebody has to read every time.
- **Removing a flag is a change like any other**: delete the check and the losing path, run the
  tests, release.
- **Tests run with the flag in the state production has**, and with the flags that are mid-rollout
  in both states. A test suite that only knows "all flags off" is testing a program nobody runs.

The repository that publishes this course lets a behaviour become a setting only when it has no
right answer, and writes down why: every knob multiplies the states somebody has to test. That is
the debt above, priced before anything is added.
