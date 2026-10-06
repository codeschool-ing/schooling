---
title: The instructions that matter
version: 1
---

**A Dockerfile has about a dozen instructions, and two pairs of them cause most of the confusion:
the two forms of `CMD`, and `ARG` against `ENV`.** Both are easiest to understand by watching what
goes wrong.

## Exec form and shell form

`CMD ["shelf"]` is the **exec form**: a JSON list, and Docker runs that program directly as the
container's process 1. Ana stops the container she started in the previous section and times it:

```
ana@vm:~/shelf$ time docker stop shelf
shelf

real	0m0.219s
user	0m0.019s
sys	0m0.013s
ana@vm:~/shelf$ docker logs shelf
2026/10/06 16:59:12 catalogue: built in, 3 books
2026/10/06 16:59:12 shelf dev listening on :8080
2026/10/06 16:59:13 received terminated, shutting down
2026/10/06 16:59:13 stopped
```

A fifth of a second. `docker stop` sent `SIGTERM`, `shelf` caught it, logged that it was shutting
down, finished its open requests and exited. Now the same image with one line changed, to the
**shell form**, the way the hadolint warning in lesson 10 complained about:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
EXPOSE 8080
CMD shelf
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.shell -t shelf:shell-form .
sha256:6e1b75f0cc9c2eab5b2699127fad0a316f14e4564e1e6778af6bd9476f92f943
ana@vm:~/shelf$ docker run -d --name shell-form shelf:shell-form
e0e947263a5484f9bcf2f4ef859a420fb8f62d71ce2634c082a1c24231215c99
```

The container runs as before. Its process list does not:

```
ana@vm:~/shelf$ docker top shell-form -o pid,ppid,args
PID                 PPID                COMMAND
17709               17681               /bin/sh -c shelf
17723               17709               shelf
```

**Process 1 is `/bin/sh -c shelf`, and `shelf` is its child.** The shell form wraps the command in a
shell, and this shell does not pass signals on to its child. Stopping it:

```
ana@vm:~/shelf$ time docker stop shell-form
shell-form

real	0m10.155s
user	0m0.017s
sys	0m0.014s
ana@vm:~/shelf$ docker logs shell-form
2026/10/06 16:59:34 catalogue: built in, 3 books
2026/10/06 16:59:34 shelf dev listening on :8080
```

**Ten seconds, and no "shutting down" in the log.** `SIGTERM` went to the shell, which ignored it;
after the default ten seconds Docker sent `SIGKILL`, which ended both at once. `shelf` never knew:
requests in flight were cut off, and a program that flushes data on exit would have lost it. That is
the same 137 lesson 7 saw from `sleep`. **Write `CMD` and `ENTRYPOINT` in exec form**, and if a
shell really is needed, end its script with `exec shelf`, so that the program replaces the shell as
process 1.

## `ENTRYPOINT` and `CMD` together

`ENTRYPOINT` is the program that always runs; `CMD` supplies its default arguments, which anything
typed after the image name in `docker run` replaces. Lesson 9's `postgres` image used exactly that,
`docker-entrypoint.sh` with `postgres` as its argument, and lesson 10's tools used it so that
`docker run mikefarah/yq:4 ".x"` ran `yq ".x"`. For a service like `shelf`, `CMD` alone is enough.

## `ARG` for the build, `ENV` for the container

Ana wants the image to know its own version, which `shelf` prints at `/version`, and a default port
that can be changed at run time:

```dockerfile
FROM golang:1.25
ARG VERSION=dev
WORKDIR /src
COPY . .
RUN go build -ldflags "-X main.version=${VERSION}" -o /usr/local/bin/shelf .
ENV PORT=8080
EXPOSE 8080
CMD ["shelf"]
```

**`ARG VERSION=dev` is a variable of the build only.** `--build-arg` sets it, and the `RUN` line
passes it to the Go linker, which stamps it into the binary. **`ENV PORT=8080` is a variable of the
image**: it is stored in the image's configuration and set in every container, where `docker run -e`
can override it.

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .
sha256:ba7af0568d99f60b56cb23c181ac458cd468b982fd09a138d52d80eed248bdf5
ana@vm:~/shelf$ docker run -d --name v1 -e PORT=9090 -p 127.0.0.1:9090:9090 shelf:1.0.0
e8846b8482d687d64eb1d2ee08a538b8d8f7bfefc46464bb5b74da4e0a9cbd83
ana@vm:~/shelf$ curl -s localhost:9090/version
1.0.0
ana@vm:~/shelf$ docker logs v1
2026/10/06 17:00:06 catalogue: built in, 3 books
2026/10/06 17:00:06 shelf 1.0.0 listening on :9090
```

The version came from the build argument, and the port from `-e`, which beat the image's `ENV`.
The image's configuration keeps one and not the other:

```
ana@vm:~/shelf$ docker image inspect shelf:1.0.0 --format "{{json .Config.Env}}"
["PATH=/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","GOLANG_VERSION=1.25.14","GOTOOLCHAIN=local","GOPATH=/go","PORT=8080"]
```

`PORT=8080` is there, beside the variables the `golang` base image set. `VERSION` is not: it existed
while the build ran. **That is why a secret must never be passed with `ENV`**, which every container
and anybody with the image can read, and why lesson 18 shows that an `ARG` is no safe place for one
either.

## The rest, in one table

| instruction | what it does | where it is taught |
| --- | --- | --- |
| `FROM` | the base image; several `FROM`s make a multi-stage build | here, and lesson 13 |
| `RUN` | runs a command at build time and keeps the result as a layer | here, and lesson 12 |
| `COPY` | copies files from the build context, or from another stage | here, and lesson 13 |
| `ADD` | like `COPY`, but also unpacks local archives and fetches URLs; use `COPY` unless you need that | here |
| `WORKDIR` | the directory later instructions and the container start in | here |
| `ENV`, `ARG` | variables of the image, and of the build | here |
| `EXPOSE` | documents a port; publishes nothing | here, and lesson 17 |
| `USER` | the user later instructions and the container run as | lesson 14 |
| `CMD`, `ENTRYPOINT` | what the container runs | here |
| `HEALTHCHECK` | how Docker tests that the program is healthy | lesson 18 |
| `LABEL` | metadata, such as the source repository and version | lesson 16 |
