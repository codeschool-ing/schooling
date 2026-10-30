---
title: Revisions, and why none of them ever changes
version: 1
---

Every time a Cloud Run service is deployed, or its configuration is changed in any way that
affects how its containers run, **Cloud Run creates a new revision: an immutable snapshot of the
image and every setting around it.** The old revision is not edited and not deleted. It stays,
with its own name, ready to receive traffic again the moment somebody asks.

## What a revision holds

A revision is the image, named by its digest, together with everything in the service's
`template`: environment variables, the CPU and memory, the concurrency, the timeout, the service
account, the scaling bounds, the network settings of lesson 12. Change any of those and the next
deployment is a new revision. What is **not** in a revision is the traffic split, which belongs to
the service, and the service's name and address. That division is what the rest of this lesson
uses: revisions are things, and traffic is a decision about them.

Revisions are named after the service, followed by a number and a random suffix that Cloud Run
generates, unless you give a suffix yourself. gcloud's own documentation says how, and it is one
of the commands this lab can run, because help needs no account:

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A5 -- '^     --revision-suffix'
     --revision-suffix=REVISION_SUFFIX
        Specify the suffix of the revision name. Revision names always start
        with the service name automatically. For example, specifying
        [--revision-suffix=v1] for a service named 'helloworld', would lead to
        a revision named 'helloworld-v1'. Set empty string to clear the suffix
        and resume server-assigned naming.
```

**Choosing the suffix makes the name predictable**, `orders-v1` and `orders-v2` instead of a
string you only learn after the deployment, which is what lets a Terraform file or a rollback
script name a revision before it exists. The rest of this lesson uses those two names.

## Two revisions, side by side at home

Nothing at home creates a revision, but the two this lesson works with can be run side by side,
each told its name the way Cloud Run tells it, through `K_REVISION`. Version 2 is the same program
with one change of configuration: `ORDERS_DELAY_MS=250`, standing in for a new database query that
turned out to be slow. From `~/gcp`, with lesson 8's image `orders:1`:

```
ana@laptop:~/gcp$ docker run -d --name orders-v1 -p 8081:8080 -e K_REVISION=orders-v1 orders:1
6cb4c04a1f23beab418e36ced682d75453a1aae51ce7afc5584440af11e5b433
ana@laptop:~/gcp$ docker run -d --name orders-v2 -p 8082:8080 -e K_REVISION=orders-v2 -e ORDERS_DELAY_MS=250 orders:1
b0d010f5bfb93cc662ea2f8fc313d1cdd41d2a34235c7eb2f7d9988ce5a7bea3
ana@laptop:~/gcp$ curl -s localhost:8081/orders | python3 -m json.tool | tail -2
    "revision": "orders-v1"
}
ana@laptop:~/gcp$ curl -s -o /dev/null -w "%{time_total}\n" localhost:8081/orders
0.001487
ana@laptop:~/gcp$ curl -s localhost:8082/orders | python3 -m json.tool | tail -2
    "revision": "orders-v2"
}
ana@laptop:~/gcp$ curl -s -o /dev/null -w "%{time_total}\n" localhost:8082/orders
0.251924
```

Each answer names its revision, which is how a log line or a response says where it came from
once traffic is split between them. And `-w "%{time_total}"` shows what the change did: **version
1 answered in a few milliseconds and version 2 in about a quarter of a second**, on this laptop.
That difference is exactly what a gradual rollout exists to catch before every user feels it, and
section 05 uses it.

## What immutability buys

A revision that never changes is the reason rolling back is safe. The revision that was serving
yesterday is still there, byte for byte and setting for setting, so sending traffic back to it
returns to a known state rather than to an attempt to reconstruct one. **A rollback on Cloud Run
is a change of traffic, not a deployment**: no build, no image pull of anything new, nothing that
can fail differently from last time.

It also means revisions accumulate. Cloud Run keeps them, up to a limit per service that Google's
quotas page sets, and a revision that serves no traffic costs nothing with request-based billing,
because it has no instances. Old revisions are deleted by hand or by a script when nobody will
roll back to them.
