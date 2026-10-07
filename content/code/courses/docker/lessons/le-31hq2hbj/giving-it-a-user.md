---
title: Giving the image a user
version: 1
---

**`USER` sets who the container's process runs as, and it belongs in every final stage.** Ana's fix
is two lines: the `nonroot` variant of distroless as the base, and a `USER` naming its unprivileged
account by number:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build -q -t shelf:nonroot .
sha256:d013d9af0537955c50a0e59dcbcb72fb0a5969d2c321b8cd769c29fb8d89e73d
ana@vm:~/shelf$ docker image inspect shelf:nonroot --format "User: [{{.Config.User}}]"
User: [65532:65532]
ana@vm:~/shelf$ docker run -d --name as-nonroot shelf:nonroot
c263c53c95dcfa89303c6b30c6956d512b9e2224e325e52e9594471e0adcc486
ana@vm:~/shelf$ docker top as-nonroot -o pid,uid,args
PID                 UID                 COMMAND
3256                65532               /shelf
```

**UID 65532.** The number is the user distroless calls `nonroot`, as its own `/etc/passwd` says;
`docker cp` can read a file out of a container even when the image has no `cat` to do it with:

```
ana@vm:~/shelf$ docker cp as-nonroot:/etc/passwd - | tar -xO
root:x:0:0:root:/root:/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin
nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
```

## Why a number and not a name

`USER nonroot` would work here, and `USER 65532:65532` is still the better habit. **A name is looked
up in the image's `/etc/passwd` when the container starts, and a number needs no lookup at all.**
Orchestrators check before starting a container that it will not run as root, and they can only be
sure from a number: Kubernetes's `runAsNonRoot` refuses an image whose `USER` is a name it cannot
verify. Writing the group as well, `:65532`, keeps the process from inheriting root's group 0.

## A low port no longer needs root

The old reason to run as root was listening on a port below 1024, which used to be reserved for
root. Ana asks `shelf`, as UID 65532, to listen on port 80:

```
ana@vm:~/shelf$ docker run -d --name low-port -e PORT=80 shelf:nonroot
5d0bec73eee313d51dfa2afcc1ea9f7c814ab554ea167f5f439db73773a8f6d5
ana@vm:~/shelf$ docker logs low-port
2026/10/06 17:30:47 catalogue: built in, 3 books
2026/10/06 17:30:47 shelf dev listening on :80
ana@vm:~/shelf$ docker run --rm alpine:3.22 cat /proc/sys/net/ipv4/ip_unprivileged_port_start
0
```

**It works.** Docker sets `ip_unprivileged_port_start` to 0 inside each container's network
namespace, so any user may bind any port there. The port inside the container rarely matters
anyway, since `-p` maps whatever the host needs onto it, as lesson 17 shows.

## The other half: files the user may write

A non-root user can only write where it has been given the right to. Ana tries a small image on
Alpine, where users are made with `adduser`, and a directory for the program's output:

```dockerfile
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.alpine -t user-demo .
sha256:78f2d6e7dca31b6938d7ac03f8cc9ffa9443bd999b656b499669def0a8ce7472
ana@vm:~/shelf$ docker run --rm user-demo
uid=10001(app) gid=10001(app) groups=10001(app)
touch: /data/report.txt: Permission denied
```

The user exists with the number Ana chose, and **cannot write to `/data`**, which `RUN mkdir` created
as root. Files and directories made during the build belong to root unless the Dockerfile says
otherwise, so the directory has to be handed over before `USER` switches:

```dockerfile
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data && chown app:app /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt && ls -l /data"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.alpine -t user-demo .
sha256:015916e39e517b57a6251d9700080a6b511be646c7bfe800286d4810bf2c3db1
ana@vm:~/shelf$ docker run --rm user-demo
uid=10001(app) gid=10001(app) groups=10001(app)
total 0
-rw-r--r--    1 app      app              0 Oct  6 17:30 report.txt
```

The rule is to give the user exactly the directories it writes to, and nothing else; `COPY --chown=`
does the same for copied files. And for data that should outlive the container, the directory is
a volume, and the volume is lesson 8's.
