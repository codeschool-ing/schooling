---
title: Cache mounts, and when the cache gets in the way
version: 1
---

**A cache mount gives one `RUN` step a directory that survives between builds without becoming part
of the image.** Layer caching is all or nothing: a step is either reused whole or run from
scratch. A cache mount lets a step that does have to run again keep its tool's own cache, so it runs
fast anyway.

## Keeping Go's build cache

Ana goes back to the simple one-`COPY` Dockerfile and adds one option to the `RUN`:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

`--mount=type=cache,target=/root/.cache/go-build` mounts a directory the builder keeps at the place
Go writes its build cache. The first build fills it:

```
ana@vm:~/shelf$ time docker build -q -t shelf:mount .
sha256:be7eb671693861f5d232d2d855e8b3ae23a02d3c72f2e23c6f8d576ac3c3c4a5

real	0m15.786s
user	0m0.121s
sys	0m0.112s
```

Then the same one-line edit to `main.go`, the one that cost 20 seconds two sections ago:

```
ana@vm:~/shelf$ sed -i "s/listening on/serving on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:mount . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [stage-0 1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [stage-0 2/4] WORKDIR /src
#6 CACHED
#7 [stage-0 3/4] COPY . .
#7 DONE 0.1s
#8 [stage-0 4/4] RUN --mount=type=cache,target=/root/.cache/go-build     go build -o /usr/local/bin/shelf .
#8 DONE 0.9s

real	0m2.147s
user	0m0.127s
sys	0m0.088s
```

**2.1 seconds.** `COPY . .` ran again, as before, and so did `go build`; but Go found the standard
library and pgx already compiled in the mounted cache and only rebuilt `shelf`. The mounted
directory belongs to the builder, not to a layer, so the build cache stays out of the image.

The two techniques combine. The ordered Dockerfile saves the work when dependencies have not
changed; a cache mount saves most of it when they have, because the package manager's cache still
holds the versions that did not move. Every package manager has such a directory: `/root/.cache/pip`
for pip, `/root/.npm` for npm, `/root/.m2` for Maven.

## Where the cache lives, and what it costs

The builder's cache is not part of any image, and it grows. `docker buildx du` reports it:

```
ana@vm:~/shelf$ docker buildx du | tail -4
Shared:		1.28GB
Private:	967MB
Reclaimable:	2.247GB
Total:		2.247GB
```

2.247GB on Ana's machine after this lesson's few builds, all of it reclaimable, because no image
needs it to run. `docker builder prune` empties it, and lesson 22 puts it in a cleaning routine with
the rest.

## When the cache gets in the way

The cache trusts its keys, and a key only knows the instruction's text and the files copied. **A
`RUN` that fetches something from the network has the same key whatever the network returns.** A
`RUN apt-get update && apt-get install -y curl` written a year ago is cached as a year-old package
list, and every build on that machine reuses it, security updates or not. Three ways out:

- **`docker build --no-cache`** ignores every cached layer for this build. It is the right command
  for a scheduled build whose purpose is to pick up updates.
- **`docker build --pull`** fetches the newest base image first, so a base that received updates
  changes every key after `FROM`.
- **A CI runner usually starts with no cache at all**, which is correct and slow. Lesson 26 shows how
  a pipeline stores the cache in a registry so that the second build of the day is fast too.
