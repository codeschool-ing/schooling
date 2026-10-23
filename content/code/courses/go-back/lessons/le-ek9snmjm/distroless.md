---
title: An image with one program in it
version: 1
---

A container image is a filesystem and a few settings. Most images start from a distribution, Debian or
Alpine, with a shell, a package manager and hundreds of programs, because most programs need some of them
at run time. **A static Go binary needs none of them.** It needs a few files a program expects to find,
and nothing else.

**Distroless** images are exactly that. Google publishes them at `gcr.io/distroless`, built from Debian
packages with everything a program does not need left out. `static-debian12` is the smallest, made for
static binaries: CA certificates, so TLS works; time-zone data; `/etc/passwd` with three users; and no
shell, no package manager, no C library. The `nonroot` tag makes its default user `nonroot`, uid 65532,
instead of root.

## The Dockerfile

```dockerfile
# boxoffice/Dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
ARG TARGETARCH
COPY dist/boxoffice-linux-${TARGETARCH} /boxoffice
ENV BOXOFFICE_HTTP=:8080 BOXOFFICE_GRPC=:9090
EXPOSE 8080 9090
ENTRYPOINT ["/boxoffice"]
```

Six instructions. **The image copies a binary built outside it**, by section 05's command; `TARGETARCH` is a
variable the builder sets to the architecture it is building for, `amd64` here, so the same file can pick
`dist/boxoffice-linux-arm64` in section 08. The two `ENV` lines make the image listen on every interface,
which is lesson 14's configuration doing the job it was written for: inside a container, `localhost` is
the container itself, and an address bound there cannot be reached from outside it. `EXPOSE` documents the
ports and publishes nothing; that is `docker run`'s job.

The build context, everything `docker build` sends to the daemon, is the directory. `.dockerignore` keeps
it to what the Dockerfile copies:

```
# boxoffice/.dockerignore
*
!dist/boxoffice-linux-*
```

Ignore everything, then let the release binaries back in. Without it, the context would include `dist/`'s
trial builds, the source and anything else lying in the directory, a secret file included.

## The binary from section 04, first

The base image comes from Google's registry, and this machine had it already:

```
ana@vm:~/boxoffice$ docker pull gcr.io/distroless/static-debian12:nonroot
nonroot: Pulling from distroless/static-debian12
Digest: sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
Status: Image is up to date for gcr.io/distroless/static-debian12:nonroot
gcr.io/distroless/static-debian12:nonroot
```

Put section 04's native build, the dynamically linked one, where the Dockerfile looks, build and run:

```
ana@vm:~/boxoffice$ cp dist/try-linux-amd64 dist/boxoffice-linux-amd64 && docker build -q -t boxoffice:dynamic . && docker run --rm boxoffice:dynamic; echo "exit $?"
sha256:bf477361cde3fb553f14b4d7c7de6e8a41942119f9e468d33c1515b8d8670e37
exec /boxoffice: no such file or directory
exit 255
```

**`exec /boxoffice: no such file or directory`**, about a file that is certainly there. The kernel read
the binary's header, found that it needs the interpreter `/lib64/ld-linux-x86-64.so.2`, and that is the
file that does not exist: the image has no C library and no loader. The message names the program because
that is what was executed. **Every Go program that fails like this in a minimal image was built with cgo
on**, and `CGO_ENABLED=0` is the fix.

## The real one

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && docker build -q -t boxoffice:v0.16.0 .
sha256:4c353c6a273fbd43931cd7d0e94d1da89b3a012a7002f0ddb31974bb440725ea
ana@vm:~/boxoffice$ docker image ls | grep -e IMAGE -e boxoffice:v -e distroless
IMAGE                                       ID             DISK USAGE   CONTENT SIZE   EXTRA
boxoffice:v0.16.0                           4c353c6a273f       30.6MB         7.35MB        
gcr.io/distroless/static-debian12:nonroot   afa5c872c891        6.9MB         1.44MB        
```

**`CONTENT SIZE` is what a registry stores and a server downloads: 7.35 MB**, of which 1.44 MB is
distroless and the rest is boxoffice, compressed. `DISK USAGE` is that plus the unpacked layers on this
machine.

And there is nothing else in it:

```
ana@vm:~/boxoffice$ docker run --rm --entrypoint sh boxoffice:v0.16.0; echo "exit $?"
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH

Run 'docker run --help' for more information
exit 127
```

No shell, so no `docker exec -it boxoffice sh` to look around. That is a cost when debugging, and the
point when somebody else gets in: a process that is broken into finds no shell, no package manager and no
tools to download more with. When you do need to look inside, `docker cp` copies files out of a
container, and a second container started with `--pid container:boxoffice` sees its processes with the
tools of its own image.
