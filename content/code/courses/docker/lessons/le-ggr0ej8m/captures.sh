#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, the `.dockerignore` from lesson 11 is written quietly, and a
# registry:3 is started on 127.0.0.1:5000 WITHOUT a password, which lesson 15
# set up and this lesson does not repeat. Every image this lesson pushes goes
# to that registry and nowhere else. The second and third versions of shelf
# are the same source built with a different VERSION: the program did not
# change, the label on it did, which is all this lesson needs.
#
# `digest TAG`, used in two commands below, is a shell function defined here
# rather than typed: it asks the registry's API for a tag's digest exactly as
# lesson 15 did with curl, and prints the first twelve hex characters.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot registry:3"
. "$(dirname "$0")/../../capture.sh"
quiet 'docker run -d --name registry -p 127.0.0.1:5000:5000 -v registry-data:/var/lib/registry registry:3'
quiet 'sleep 2'
cd shelf
staged .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
staged Dockerfile <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
DF

block default-latest
run 'docker build -q --build-arg VERSION=1.0.0 -t shelf .'
run 'docker image ls shelf'

block latest-moves
run 'docker tag shelf localhost:5000/shelf && docker push -q localhost:5000/shelf'
run 'docker run -d --name web-a localhost:5000/shelf'
run 'docker build -q --build-arg VERSION=1.1.0 -t localhost:5000/shelf .'
run 'docker push -q localhost:5000/shelf'
run 'docker run -d --name web-b localhost:5000/shelf'
quiet 'sleep 1'
run 'docker ps --format "{{.Names}}\t{{.Image}}"'
run 'docker logs web-a 2>&1 | tail -1; docker logs web-b 2>&1 | tail -1'
run 'docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}"'
quiet 'docker rm -f web-a web-b'

block labels
put Dockerfile <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED
LABEL org.opencontainers.image.title="shelf" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.source="https://git.example.com/ana/shelf"
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
DF

block build-tags
run 'git log -1 --format="%h %cI %s"'
run 'REV=$(git rev-parse --short HEAD); CREATED=$(git log -1 --format=%cI)'
run 'docker build -q --build-arg VERSION=1.2.3 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.3 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 -t localhost:5000/shelf:sha-$REV .'
run 'docker image inspect localhost:5000/shelf:1.2.3 --format "{{json .Config.Labels}}" | jq .'

block push-all
run 'docker push -q --all-tags localhost:5000/shelf'
run 'curl -s localhost:5000/v2/shelf/tags/list'

block patch
run 'docker build -q --build-arg VERSION=1.2.4 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.4 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 .'
run 'docker push -q --all-tags localhost:5000/shelf'
quiet 'docker image rm -f $(docker image ls -q localhost:5000/shelf | sort -u)'
digest() { curl -s -o /dev/null -D - -H "Accept: application/vnd.oci.image.index.v1+json" "localhost:5000/v2/shelf/manifests/$1" | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print substr($2,1,19)}'; }
run 'for t in 1.2.3 1.2.4 1.2 1 sha-$REV latest; do printf "%-12s %s\n" $t $(digest $t); done'

block overwrite
run 'docker build -q --build-arg VERSION=9.9.9 -t localhost:5000/shelf:1.2.3 .'
run 'docker push -q localhost:5000/shelf:1.2.3'
run 'printf "%-12s %s\n" 1.2.3 $(digest 1.2.3)'

block base-digests
run 'docker image inspect golang:1.25 --format "{{index .RepoDigests 0}}"'
run 'docker image inspect gcr.io/distroless/static-debian12:nonroot --format "{{index .RepoDigests 0}}"'
GO=$(docker image inspect golang:1.25 --format '{{index .RepoDigests 0}}' | cut -d@ -f2)
DL=$(docker image inspect gcr.io/distroless/static-debian12:nonroot --format '{{index .RepoDigests 0}}' | cut -d@ -f2)

block pinned
put Dockerfile <<DF
FROM golang:1.25@$GO AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=\${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot@$DL
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
DF
run 'docker build --build-arg VERSION=1.3.0 -t shelf:1.3.0 . 2>&1 | grep -E "load metadata|\[(build|stage-1) 1/" | awk '\''!seen[$0]++'\'''

block deploy-digest
run 'docker tag shelf:1.3.0 localhost:5000/shelf:1.3.0 && docker push -q localhost:5000/shelf:1.3.0'
run 'D=$(docker image inspect shelf:1.3.0 --format "{{.Id}}"); echo $D'
run 'docker run -d --name web localhost:5000/shelf@$D'
quiet 'sleep 1'
run 'docker inspect web --format "{{.Config.Image}}"'
run 'docker logs web 2>&1 | tail -1'
