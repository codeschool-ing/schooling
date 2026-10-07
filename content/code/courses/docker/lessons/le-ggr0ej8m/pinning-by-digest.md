---
title: Pinning by digest
version: 1
---

**A digest names content, so a reference with one can only ever mean those bytes.** Lesson 15
pulled `shelf` back by digest. This section uses digests in the two places that decide what runs:
the `FROM` lines of a Dockerfile, and the image a deployment starts.

## Pinning the bases

Ana's machine already knows the digest of each base image it pulled:

```
ana@vm:~/shelf$ docker image inspect golang:1.25 --format "{{index .RepoDigests 0}}"
golang@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
ana@vm:~/shelf$ docker image inspect gcr.io/distroless/static-debian12:nonroot --format "{{index .RepoDigests 0}}"
gcr.io/distroless/static-debian12@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
```

She writes them into the Dockerfile, after the tag. **The tag stays for people**, so that a reader
still sees "Go 1.25" and "distroless static, nonroot"; **the digest is what Docker uses**:

```dockerfile
FROM golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build --build-arg VERSION=1.3.0 -t shelf:1.3.0 . 2>&1 | grep -E "load metadata|\[(build|stage-1) 1/" | awk '!seen[$0]++'
#2 [internal] load metadata for gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
#3 [internal] load metadata for docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#5 [stage-1 1/2] FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
#6 [build 1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
```

BuildKit resolves both bases by digest. If `golang:1.25` moves tomorrow to a build with a new patch
release of Go, this Dockerfile does not notice. **That is the point and also the cost**: the security
fix in the new base does not arrive either, until somebody changes the line.

## Keeping pins fresh

A pin nobody updates is a slow way of running old software. The usual answer is a bot that watches
the tags and opens a pull request when one moves, with the new digest in it, so the change is
reviewed and tested like any other. **Dependabot**, built into GitHub, and **Renovate** both do
this for Dockerfiles. Neither runs in the lab, which has no repository host; what the pull request
changes is exactly the `@sha256:` part of a line like the ones above.

So the trade is not "pin or get fixes". It is **who decides when the base changes**: the publisher,
at a moment you did not choose, or a reviewed pull request, at a moment you did.

## Deploying by digest

Ana pushes `shelf:1.3.0` and starts it by digest rather than by tag:

```
ana@vm:~/shelf$ docker tag shelf:1.3.0 localhost:5000/shelf:1.3.0 && docker push -q localhost:5000/shelf:1.3.0
localhost:5000/shelf:1.3.0
ana@vm:~/shelf$ D=$(docker image inspect shelf:1.3.0 --format "{{.Id}}"); echo $D
sha256:e836fe6cf919996615b001372a8bb55f76268c6d1f43de798f02d7909e33638e
ana@vm:~/shelf$ docker run -d --name web localhost:5000/shelf@$D
c70c0addfb590dea86799365df113ffb26873b97ea1fd6a78a995068f20675e1
ana@vm:~/shelf$ docker inspect web --format "{{.Config.Image}}"
localhost:5000/shelf@sha256:e836fe6cf919996615b001372a8bb55f76268c6d1f43de798f02d7909e33638e
ana@vm:~/shelf$ docker logs web 2>&1 | tail -1
2026/10/06 17:48:06 shelf 1.3.0 listening on :8080
```

`docker inspect` records the reference the container was started from, and it is the digest. Whatever
happens to the tag `1.3.0` afterwards, including the overwrite of the previous section, this
container and every one started from the same line run the same bytes.

**Kubernetes deployments, Compose files and CI pipelines all accept `name@sha256:…`**, and the
pipeline in lesson 26 writes the digest of what it pushed into its output, so that the step that
deploys can use it. Tags are for people to read and search; digests are for machines to run.
