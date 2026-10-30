---
title: A gradual rollout, and the way back
version: 1
---

Splitting traffic is a mechanism. **A gradual rollout is a procedure built on it: move a small
share to the new revision, watch something that would show a problem, and either move more or
move everything back.** The mechanism is the same command every time; what makes a rollout safe is
deciding in advance what you watch and what makes you stop.

## The commands

gcloud's help lists the moves as examples, and they are the whole vocabulary:

```
ana@laptop:~/gcp$ gcloud run services update-traffic --help | sed -n '/^EXAMPLES/,/^POSITIONAL/p'
EXAMPLES
    To assign 10% of traffic to revision myservice-s5sxn and 90% of traffic to
    revision myservice-cp9kw run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-s5sxn=10,myservice-cp9kw=90

    To increase the traffic to revision myservice-s5sxn to 20% and by reducing
    the traffic to revision myservice-cp9kw to 80% run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-s5sxn=20

    To rollback to revision myservice-cp9kw run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-cp9kw=100

    To assign 100% of traffic to the current or future LATEST revision run:

        $ gcloud run services update-traffic myservice --to-latest

    You can also refer to the current or future LATEST revision in
    --to-revisions by the string "LATEST". For example, to set 10% of traffic
    to always float to the latest revision:

        $ gcloud run services update-traffic myservice \
          --to-revisions=LATEST=10

POSITIONAL ARGUMENTS
```

Read them as one sequence. **10% to the new revision; then 20%; then, if it goes wrong, 100% back
to the old one**, which is a rollback in one command and, as section 02 explained, no deployment at
all. `--to-latest` is the last step of a rollout that went well: everything to the newest
revision, and future deployments too.

## What to watch, and for how long

Section 02's `orders-v2` answered in about a quarter of a second where `orders-v1` took a few
milliseconds, on the laptop. On Cloud Run that difference would show in the service's latency
metrics, broken down by revision, which Cloud Monitoring collects without any code; `gcp-operations`
covers the dashboards and the alerts. The decision rule is written before the rollout starts, for
example: **if the 95th percentile of `orders-v2` is more than 20% above `orders-v1`'s, or its
error rate above 1%, move everything back.**

How long to watch depends on how much traffic the share receives, because a percentage of very
little is very little. The shop's orders service takes about 2,000 requests an hour in the
afternoon. At 10%, `orders-v2` sees about 200 an hour, enough to see a doubling of latency in
minutes and too few to see an error that happens once in a thousand. A rare error needs either more
time or a bigger share, and the arithmetic says which: to expect ten occurrences of a
one-in-a-thousand error at 10% of 2,000 an hour takes fifty hours, at 50% it takes ten.

## Doing it by hand, and not doing it by hand

A rollout run by somebody typing `update-traffic` every hour works, and it is how most teams start.
It fails in a predictable way: the person gets busy, a stage lasts a day instead of an hour, or the
check is skipped because the last ten went fine. **Google Cloud Deploy automates exactly this
procedure for Cloud Run**, with stages declared in advance and the traffic moved by the pipeline,
and `gcp-operations` returns to it. What it automates is the procedure above; it does not decide
what to watch, which is still yours to write down.

## The way back, rehearsed

A rollback is only fast if it has been done before somebody needs it. Two things keep it fast:
**the old revision must still exist**, so it is not deleted while a newer one is on probation; and
**its configuration must still work**, so a revision that depended on a database column the new
code removed is not a revision you can go back to. That second one is not about Cloud Run at all,
and it is the usual reason a rollback fails: the code went back and the data did not.
