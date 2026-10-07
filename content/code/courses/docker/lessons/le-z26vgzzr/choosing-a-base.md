---
title: Choosing a final base
version: 1
---

**The final stage's base is a choice between how little the image contains and how much the program
expects to find.** A program that needs nothing can ship on nothing at all; most programs need a
little, and finding out which little is the work.

## `scratch`, and the library that was not there

`scratch` is not an image: it is the empty filesystem, the start of every image's history. Ana tries
it, with a build stage that forgets `CGO_ENABLED=0`:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN go build -o /out/shelf .

FROM scratch
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch -t shelf:scratch .
sha256:4c2ff6d60a8337b3f7007acc8ecc01790fa8585e21d136b28a403f3e10b14c43
ana@vm:~/shelf$ docker run --rm shelf:scratch
exec /shelf: no such file or directory
```

**`exec /shelf: no such file or directory`, about a file that is plainly there.** The message is
misleading in a way that costs people hours. The file exists; what does not exist is the program
that has to load it. `--target build` builds only the first stage, so Ana can look at the binary in
the image where it was made:

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch --target build -t shelf:build-stage .
sha256:554a36b60c66936487fad95a782e028698b3779d6bb956333f2ba5f9c9c6e377
ana@vm:~/shelf$ docker run --rm shelf:build-stage ldd /out/shelf
	linux-vdso.so.1 (0x00007f00c83c1000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f00c81c2000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f00c83c3000)
```

`ldd` lists the shared libraries a binary needs at run time. This one needs the C library,
`libc.so.6`, and the dynamic loader, `/lib64/ld-linux-x86-64.so.2`, because Go links against the C
library when a C compiler is available, which it is in `golang:1.25`, and the standard library's
network code uses it. `scratch` has neither, so the kernel cannot start the program, and says "no
such file" about the loader it could not find. With `CGO_ENABLED=0`:

```
ana@vm:~/shelf$ sed -i "s/RUN go build -o/RUN CGO_ENABLED=0 go build -o/" Dockerfile.scratch
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch -t shelf:scratch .
sha256:cce8089a2be62e97415b2bf0467b62244fef68587302c6f5a9d660f81109e726
ana@vm:~/shelf$ docker run --rm -d --name scratch shelf:scratch
486dabeb53ca6c75043dbc02c7ca15d230403a7df15ef570732096defdf82504
ana@vm:~/shelf$ docker logs scratch
2026/10/06 17:23:36 catalogue: built in, 3 books
2026/10/06 17:23:36 shelf dev listening on :8080
ana@vm:~/shelf$ docker image ls shelf:scratch
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:scratch   cce8089a2be6       21.9MB         7.12MB   U    
```

A fully static binary, which runs on nothing, in an image of 21.9MB on disk.

## What each base gives you

| base | what is in it | when it fits |
| --- | --- | --- |
| `scratch` | nothing | a fully static binary that needs no certificates, no time zones, no users |
| `gcr.io/distroless/static-debian12` | CA certificates, time zones, `/etc/passwd`, a non-root user; no shell | a static binary that makes TLS connections or prints local times, which is most of them |
| `gcr.io/distroless/base-debian12` | the above plus the C library | a dynamically linked binary that needs `libc` and nothing else |
| `alpine:3.22` | a small Linux with a shell and a package manager, built on `musl` | when you want a shell inside, or need packages from Alpine |
| `debian:trixie-slim` | a small Debian with `glibc`, a shell and `apt` | interpreted languages and programs that expect a normal Linux |

Two traps sit in that table. **`scratch` has no CA certificates**, so a program in it that calls an
HTTPS service fails to verify every certificate; distroless `static` exists to fix exactly that.
And **Alpine uses `musl` instead of `glibc`**: a binary compiled against `glibc` does not run on it,
for the same reason `shelf` did not run on `scratch`, and some programs behave differently on
`musl`. Interpreted languages carry their own runtime and so ship on `-slim` images of their own,
like the `python:3.13-slim` of lesson 10, built the same way with a build stage that installs what
needs compiling.
