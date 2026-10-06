#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and the `.dockerignore` from lesson 11 is written quietly. The
# `sleep` between starting a container and reading its state is the script's;
# the prose says how long each one was. `token.txt` holds a lab value, not a
# credential for anything. The daemon's own configuration is NOT changed in
# this lesson: the `daemon.json` it shows for log rotation is printed, not
# applied, and the prose says so.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22"
. "$(dirname "$0")/../../capture.sh"
cd shelf
cat > .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN

block log-driver
run 'docker info --format "{{.LoggingDriver}}"'
run 'docker run -d --name chatty alpine:3.22 yes "one more line of log"'
quiet 'sleep 3'
run 'docker logs --tail 2 chatty'
run 'docker inspect chatty --format "{{.LogPath}}"'
run 'sudo du -h "$(docker inspect chatty --format "{{.LogPath}}")"'
quiet 'docker rm -f chatty'

block log-rotate
run 'docker run -d --name chatty --log-opt max-size=1m --log-opt max-file=3 alpine:3.22 yes "one more line of log"'
quiet 'sleep 3'
run 'sudo ls -l "$(dirname "$(docker inspect chatty --format "{{.LogPath}}")")" | grep json.log'
quiet 'docker rm -f chatty'

block daemon-json
put daemon.json.example <<'JSON'
{
  "registry-mirrors": ["https://mirror.gcr.io"],
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
JSON

block probe
put probe/main.go <<'GO'
// probe exits 0 when a GET of its one argument answers 200, and 1 otherwise.
// It is the health check for an image that has no shell and no curl.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	c := http.Client{Timeout: 2 * time.Second}
	r, err := c.Get(os.Args[1])
	if err != nil || r.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
GO

block health-dockerfile
put Dockerfile <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 go build -o /out/probe ./probe

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
DF
run 'docker build -q --build-arg VERSION=1.4.0 -t shelf:1.4.0 .'

block healthy
run 'docker run -d --name web shelf:1.4.0'
run 'docker ps --format "table {{.Names}}\t{{.Status}}"'
quiet 'sleep 8'
run 'docker ps --format "table {{.Names}}\t{{.Status}}"'
run 'docker inspect web --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"'

block unhealthy
run 'docker run -d --name web-9090 -e PORT=9090 shelf:1.4.0'
quiet 'sleep 25'
run 'docker ps --format "table {{.Names}}\t{{.Status}}"'
run 'docker inspect web-9090 --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"'
quiet 'docker rm -f web web-9090'

block leak
put Dockerfile.leak <<'DF'
FROM alpine:3.22
ARG REGISTRY_TOKEN
RUN printf 'machine git.example.com login ana password %s\n' "$REGISTRY_TOKEN" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
DF
run 'docker build -q -f Dockerfile.leak --build-arg REGISTRY_TOKEN=lab-only-token -t leak .'
run 'docker history --no-trunc --format "{{.CreatedBy}}" leak | head -1'

block secret-mount
put token.txt <<'TXT'
lab-only-token
TXT
quiet 'chmod 600 token.txt'
put Dockerfile.secret <<'DF'
FROM alpine:3.22
RUN --mount=type=secret,id=registry_token \
    printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
DF
run 'docker build -f Dockerfile.secret --secret id=registry_token,src=token.txt -t no-leak . 2>&1 | grep -E "^#[0-9]+ \[2/2\]|fetched"'
run 'docker history --no-trunc --format "{{.CreatedBy}}" no-leak | head -1'
run 'docker run --rm no-leak ls /run/secrets /root'
