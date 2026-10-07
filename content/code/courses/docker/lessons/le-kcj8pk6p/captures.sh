#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 is built quietly from the lesson 14 Dockerfile,
# which is written by `put` and not shown again. The registry is the official
# `registry:3` image on Ana's machine; its password is a lab value. Nothing in
# this lesson logs in to Docker Hub, GHCR, ECR, Artifact Registry or ACR: the
# lab has no account there, and the lesson marks those commands as not run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22 registry:3 httpd:2"
. "$(dirname "$0")/../../capture.sh"
cd shelf
cat > .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
cat > Dockerfile <<'DF'
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
quiet 'docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .'
cd ..

block full-name
run 'docker image ls alpine'
run 'docker image inspect alpine:3.22 --format "{{json .RepoDigests}}"'
run 'docker image inspect docker.io/library/alpine:3.22 --format "{{.Id}}"'
run 'docker image inspect alpine:3.22 --format "{{.Id}}"'

block htpasswd
run 'mkdir auth && docker run --rm --entrypoint htpasswd httpd:2 -Bbn ana lab-only > auth/htpasswd'
run 'cut -c1-20 auth/htpasswd'
block registry
run 'docker run -d --name registry -p 127.0.0.1:5000:5000 -v registry-data:/var/lib/registry -v "$PWD/auth":/auth:ro -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM=lab -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd registry:3'
quiet 'sleep 2'
block tag
run 'docker tag shelf:1.0.0 localhost:5000/shelf:1.0.0'
run 'docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" | grep shelf'
block push-denied
run 'docker push localhost:5000/shelf:1.0.0'
block login
run 'echo lab-only | docker login localhost:5000 -u ana --password-stdin'
run 'jq . ~/.docker/config.json'
run 'jq -r ".auths[\"localhost:5000\"].auth" ~/.docker/config.json | base64 -d; echo'
block push
run 'docker push localhost:5000/shelf:1.0.0'
block api
run 'curl -s -u ana:lab-only localhost:5000/v2/_catalog'
run 'curl -s -u ana:lab-only localhost:5000/v2/shelf/tags/list'
run 'curl -s -u ana:lab-only -o /dev/null -D - -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/shelf/manifests/1.0.0 | grep -i -E "content-type|docker-content-digest"'
DIGEST=$(curl -s -u ana:lab-only -o /dev/null -D - -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/shelf/manifests/1.0.0 | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}')
block by-digest
run 'docker image rm shelf:1.0.0 localhost:5000/shelf:1.0.0'
run "docker pull localhost:5000/shelf@$DIGEST"
run "docker run -d --name from-registry localhost:5000/shelf@$DIGEST"
quiet 'sleep 1'
run 'docker logs from-registry'
block logout
run 'docker logout localhost:5000'
run 'jq . ~/.docker/config.json'
