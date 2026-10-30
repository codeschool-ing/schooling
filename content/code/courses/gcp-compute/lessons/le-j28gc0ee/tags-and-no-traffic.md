---
title: Tags and deploying with no traffic
version: 1
---

A percentage sends real users to a revision. Often you want the opposite first: **the new
revision running, reachable by you and your tests, and by nobody else.** Cloud Run does that with
two features that are usually used together, a deployment that takes no traffic and a tag that
gives the revision an address of its own.

## Deploying with no traffic

By default a deployment moves the `LATEST` share to the new revision, which with the default split
is everything. The flag that prevents it is documented in gcloud's help, which this lab can read:

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A9 -- '^     --no-traffic'
     --no-traffic
        True to avoid sending traffic to the revision being deployed. Setting
        this flag assigns any traffic assigned to the LATEST revision to the
        specific revision bound to LATEST before the deployment. The effect is
        that the revision being deployed will not receive traffic.

        After a deployment with this flag the LATEST revision will not receive
        traffic on future deployments. To restore sending traffic to the LATEST
        revision by default, run the gcloud run services update-traffic command
        with --to-latest.
```

**`--no-traffic` freezes the split as it was**: whatever share `LATEST` had is pinned to the
revision that was latest before the deployment, so the new revision receives none of the service's
traffic. The help's second paragraph is the part people miss. After one deployment with this flag,
**later deployments do not take traffic either**, because nothing points at `LATEST` any more,
until somebody runs `update-traffic --to-latest`. A team that used the flag once for a careful
release and forgot it can deploy a fix several times and wonder why nobody sees it.

## A tag is an address

A **tag** is a name attached to a revision in the traffic list, with `percent = 0` if it should
take no share. The `canary` tag in the last section's `main.tf` is one. Cloud Run gives every tag
an address of its own, made by putting the tag in front of the service's address with three
hyphens: for a service at `https://orders-….run.app`, the tag answers at
`https://canary---orders-….run.app`. The dots stand for the part of the address Google generates,
which this lab cannot show and does not invent.

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A2 -- '^     --tag=TAG'
     --tag=TAG
        Traffic tag to assign to the newly created revision.
```

**A request to the tag's address always reaches that revision**, whatever the split says. So the
usual sequence is: deploy with `--no-traffic --tag=canary`, run the tests and a few requests by
hand against the tag's address, and only then give the revision a percentage. The tag stays useful
afterwards: while the canary takes 10%, its address still lets you compare it with the stable
revision request for request.

## Who can reach a tag

A tag's address is as public as the service's. If the service allows unauthenticated requests,
anybody who guesses or learns the tag's address can use the unfinished revision, and tag names
like `canary`, `test` or `next` are easy to guess. Two habits keep that small. **Remove the tag
when the rollout is over**, so the address stops existing. And for a service that must not be
public, require authentication at the service, which applies to its tags too; lesson 12 covers
the network side.
