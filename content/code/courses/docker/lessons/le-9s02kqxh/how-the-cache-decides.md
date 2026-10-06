---
title: How the cache decides
version: 1
---

**Every instruction in a Dockerfile produces a layer, and the builder keeps each one with a key:
the layer it was built on, plus the instruction, plus, for `COPY`, the checksum of every file it
copied.** On the next build, an instruction whose key matches is not run at all; its old layer is
reused. That single rule decides whether a build takes a third of a second or twenty.

Ana starts from the simple Dockerfile of lesson 11 and builds it once, from an empty cache:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

```
ana@vm:~/shelf$ time docker build -q -t shelf:dev .
sha256:190e7499645fd64e21608781bb5ecae079f675aceb36961af9c505062360c62a

real	0m30.232s
user	0m0.222s
sys	0m0.145s
```

## The layers it made

`docker history` lists an image's layers, newest at the top, with the instruction that made each
one and its size:

```
ana@vm:~/shelf$ docker history shelf:dev
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
190e7499645f   6 seconds ago    CMD ["shelf"]                                   0B        buildkit.dockerfile.v0
<missing>      6 seconds ago    RUN /bin/sh -c go build -o /usr/local/bin/sh…   146MB     buildkit.dockerfile.v0
<missing>      20 seconds ago   COPY . . # buildkit                             8.73MB    buildkit.dockerfile.v0
<missing>      20 seconds ago   WORKDIR /src                                    8.19kB    buildkit.dockerfile.v0
<missing>      6 weeks ago      WORKDIR /go                                     4.1kB     buildkit.dockerfile.v0
<missing>      6 weeks ago      RUN /bin/sh -c mkdir -p "$GOPATH/src" "$GOPA…   16.4kB    buildkit.dockerfile.v0
<missing>      6 weeks ago      COPY /target/ / # buildkit                      255MB     buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV PATH=/go/bin:/usr/local/go/bin:/usr/loca…   0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOPATH=/go                                  0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOTOOLCHAIN=local                           0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOLANG_VERSION=1.25.14                      0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   287MB     buildkit.dockerfile.v0
<missing>      2 months ago     RUN /bin/sh -c set -eux;  apt-get update;  a…   202MB     buildkit.dockerfile.v0
<missing>      2 months ago     RUN /bin/sh -c set -eux;  apt-get update;  a…   65MB      buildkit.dockerfile.v0
<missing>      2 months ago     # debian.sh --arch 'amd64' out/ 'trixie' '@1…   134MB     debuerreotype 0.17
```

The top four rows are Ana's instructions, and everything under them came with `golang:1.25`, down
to the Debian `trixie` filesystem at the bottom. **The `RUN go build` layer is 146MB**, far more than
one program: it also holds Go's build cache, which `go build` wrote under `/root/.cache` while it
compiled the standard library and pgx. Lesson 13 leaves all of that behind.

## The same build, again

Nothing changed, so every key matches. The build output is long, so from here on Ana filters it
with `awk` to the lines that name a step of her Dockerfile and say how it ended:

```
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 CACHED
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 CACHED

real	0m0.313s
user	0m0.109s
sys	0m0.107s
```

**Every step `CACHED`, and the whole build took 0.313 seconds.** No file was copied and nothing was
compiled; the builder checked the keys and pointed `shelf:dev` at the layers it already had.

## What counts as a change

The key of a `COPY` comes from the content of the files it copies, so changing one byte of one of
them changes the key. And once a step's key changes, **every
step after it is rebuilt**, because each of their keys includes the layer underneath, which is now
a different one. The next section turns that rule from a fact into a design decision.

| what changed | what is rebuilt |
| --- | --- |
| nothing | nothing; every step is `CACHED` |
| a file that a `COPY` copies | that `COPY` and every step after it |
| a line of the Dockerfile | that instruction and every step after it |
| the base image, after a new pull | everything |
| a file `.dockerignore` excludes | nothing; the builder never saw it |
