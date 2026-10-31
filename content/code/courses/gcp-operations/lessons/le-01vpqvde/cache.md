---
title: The cache a build does not have, and what a minute costs
version: 1
---

**Every Cloud Build build starts on a fresh machine, so by default it has no cache.** On your laptop
the second `docker build` reuses the layers of the first. On Cloud Build there is no first: the
machine that ran yesterday's build is gone, and today's pulls the base image and runs every
instruction of the Dockerfile again. A build that takes forty seconds on a laptop and four minutes
in the pipeline is usually this, not a slower machine.

You can see the difference on your own computer by emptying Docker's build cache, which is the
state a Cloud Build machine starts in, and building twice:

```
ana@laptop:~/gcp/shop$ docker build --progress=plain -t shop-api:cold api 2>&1 | grep -E '^#[67] '
#6 [2/3] WORKDIR /app
#6 DONE 0.2s
#7 [3/3] COPY app.py .
#7 DONE 0.0s
ana@laptop:~/gcp/shop$ docker build --progress=plain -t shop-api:warm api 2>&1 | grep -E '^#[67] '
#6 [2/3] WORKDIR /app
#6 CACHED
#7 [3/3] COPY app.py .
#7 CACHED
```

The first build ran both instructions; the second found their results in the cache and ran neither.
The shop's Dockerfile is three lines, so the difference is a fraction of a second here. With a
dependency install in the middle (a `pip install` of forty packages, an `npm ci`), it is minutes,
on every build, paid in build minutes.

## Three ways to bring a cache back

None of these was run here: they need a registry and a build machine.

- **`--cache-from` an image you already pushed.** The build's first step pulls the last image, and
  `docker build --cache-from` treats its layers as a cache. With BuildKit the image has to have been
  built with `--build-arg BUILDKIT_INLINE_CACHE=1`, which writes the cache metadata into it. It
  costs one pull at the start of every build and is the simplest of the three.
- **Kaniko with `--cache=true`.** Kaniko is a builder Google published that builds an image without
  a Docker daemon and keeps each layer it builds as an image in a repository of its own, so the next
  build fetches only the layers it needs. Its project is no longer maintained by Google, which is a
  reason to prefer the first option for a new build.
- **A smaller build.** Copying the dependency list and installing it **before** copying the code
  means a change to the code leaves the expensive layer untouched, and that holds for every one of
  the options above. The shop's Dockerfile copies `app.py` last for the same reason.

## What a build minute costs

Cloud Build charges by the minute a build is running, from the moment it starts until it ends, and
not for the time it waits in the queue. Partial minutes are billed by the second. Its pricing page,
read on 30 October 2026, gives one table for the default pool in every region it lists, São Paulo
among them:

| machine type | vCPUs | memory | USD per minute |
|---|---|---|---|
| `e2-medium` | 1 | 4 GB | 0.003 |
| `e2-standard-2` (the default) | 2 | 8 GB | 0.006 |
| `e2-highcpu-8` | 8 | 8 GB | 0.0156 |
| `e2-highcpu-32` | 32 | 32 GB | 0.0624 |

**Each billing account gets 2,500 build minutes a month free** on `e2-standard-2` in the default
pool, and the page says that the allowance is promotional and may change. So the shop's build, at
six minutes, run twenty times a working day for 22 days, is 440 × 6 = 2,640 minutes; less the 2,500
free ones, that is 140 minutes at 0.006 USD, or 0.84 USD for the month. Without the free minutes it
would be 15.84 USD. A cache that took the build from six minutes to two would cut the minutes to
880 and the bill, inside the free allowance, to nothing.

**Those are list prices on the date above**, from a page that changes without notice. Lesson 21
is about the discounts, and lesson 23 about reading the line a build adds to the bill.
