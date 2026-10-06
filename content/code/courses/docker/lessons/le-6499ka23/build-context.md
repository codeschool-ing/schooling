---
title: The build context and .dockerignore
version: 1
---

**The builder does not read your disk.** `docker build .` packs the directory `.` and sends it to
the builder, and that copy, the **build context**, is the only place `COPY` can take files from.
Whatever is in the directory goes, unless a file called `.dockerignore` says otherwise, and two
kinds of thing make that matter: what is large, and what is secret.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"On the left, Ana&#x27;s project directory: .git, .env, testdata with a 300 MB dump, vendor, go.mod and the .go files. A .dockerignore filter in the middle drops .git, .env and testdata. On the right, the build context the builder receives: vendor, go.mod, go.sum and the .go files. COPY . . can only copy from the context, so whatever passed the filter can end up in the image.\"><defs><marker id=\"l11ctx-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11ctx-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"240\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">~/shelf, on disk</text><text x=\"30\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">.git</text><path d=\"M28 64 L62 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">.env</text><path d=\"M28 94 L62 94\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">testdata/  300M</text><path d=\"M28 124 L150 124\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vendor/</text><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">go.mod  go.sum</text><text x=\"30\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.go  postgres.go</text><rect x=\"290\" y=\"95\" width=\"140\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.dockerignore</text><text x=\"360\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">drops what is listed</text><path d=\"M252 133 L286 133\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11ctx-ah-wire)\"></path><path d=\"M432 133 L466 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11ctx-ah-phosphor)\"></path><rect x=\"470\" y=\"20\" width=\"240\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"486\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the build context</text><text x=\"490\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vendor/</text><text x=\"490\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">go.mod  go.sum</text><text x=\"490\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.go  postgres.go</text><text x=\"490\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*_test.go</text><text x=\"490\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what COPY . . can copy</text><text x=\"490\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">into the image</text></svg>", "caption": "The builder never reads your disk; it reads what the client sent. .dockerignore decides what is sent, and COPY can only take from that."}
```

## What gets sent

A month later, Ana's directory has gained two things that are normal in a working copy: a 300 MB
database export she uses for testing, and a `.env` file with the connection string for her local
database:

```
ana@vm:~/shelf$ mkdir -p testdata && head -c 300M /dev/urandom > testdata/catalogue-dump.sql
ana@vm:~/shelf$ du -sh .git vendor testdata
3.9M	.git
8.3M	vendor
301M	testdata
```

```
DATABASE_URL=postgres://shelf:s3cret-from-ana@db:5432/shelf
```

She builds again:

```
ana@vm:~/shelf$ docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"
#3 transferring context: 2B done
#5 transferring context: 314.72MB 1.8s done
#9 naming to docker.io/library/shelf:dev done
```

**314.72MB transferred**, where the first build sent 10.03MB. Here that took 1.8 seconds, on one
machine; on Docker Desktop, where the context crosses into a VM, or to a builder across a network,
the same bytes travel on every build that changed them. And `COPY . .` copied all of it into the image:

```
ana@vm:~/shelf$ docker run --rm shelf:dev ls -a /src
.
..
.env
.git
Dockerfile
Dockerfile.shell
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
testdata
vendor
ana@vm:~/shelf$ docker run --rm shelf:dev cat /src/.env
DATABASE_URL=postgres://shelf:s3cret-from-ana@db:5432/shelf
```

**The password is in the image.** Anyone who pulls `shelf:dev` from a registry can read it, along
with the whole git history in `.git`, and the database export too. Deleting the file in a later
instruction does not help, because lesson 14 shows that an earlier layer keeps everything it had.

## Keeping things out

`.dockerignore` sits beside the Dockerfile and lists what the client must not send, in a syntax
close to `.gitignore`'s:

```
.git
.env
testdata/
Dockerfile*
.dockerignore
```

```
ana@vm:~/shelf$ docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"
#3 transferring context: 86B done
#5 transferring context: 22.75kB 0.2s done
#9 naming to docker.io/library/shelf:dev done
ana@vm:~/shelf$ docker run --rm shelf:dev ls -a /src
.
..
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
vendor
```

The image's `/src` now holds the source and the vendored dependency, and nothing else. The context
line says 22.75kB this time, which is less than `vendor/` alone: BuildKit keeps the files of earlier
builds and sends only what changed since, so the number counts the transfer, not the size of the
context. The first build of a fresh builder pays for the whole of it.

Three habits follow:

- **Start every project's `.dockerignore` with `.git` and every file that holds a secret**, before the
  first build, because the first build is the one that leaks.
- **List the Dockerfile and `.dockerignore` themselves**, as Ana did: the image does not need them,
  and leaving them out means editing them does not change what `COPY . .` copies.
- **Prefer copying what the image needs over copying everything and excluding.** `COPY go.mod go.sum
  ./` and `COPY *.go ./` say exactly what goes in; lesson 12 rewrites this Dockerfile that way for a
  reason of its own.
