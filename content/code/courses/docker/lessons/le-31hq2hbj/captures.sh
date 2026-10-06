#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the base images are pulled before the first
# command; the Dockerfiles and the .dockerignore are written by `put`. The
# 50 MB file in the layer experiment is random bytes from `dd`, standing in
# for a package cache or a downloaded archive.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, BuildKit, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:latest gcr.io/distroless/static-debian12:nonroot alpine:3.22 debian:trixie debian:trixie-slim"
. "$(dirname "$0")/../../capture.sh"
cd shelf

put .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
put Dockerfile <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
DF
block root
run 'docker build -q -t shelf:root .'
run 'docker image inspect shelf:root --format "User: [{{.Config.User}}]"'
run 'docker run -d --name as-root shelf:root'
quiet 'sleep 1'
run 'docker top as-root -o pid,uid,args'

put ./Dockerfile <<'DF'
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
DF
block nonroot
run 'docker build -q -t shelf:nonroot .'
run 'docker image inspect shelf:nonroot --format "User: [{{.Config.User}}]"'
run 'docker run -d --name as-nonroot shelf:nonroot'
quiet 'sleep 1'
run 'docker top as-nonroot -o pid,uid,args'
block passwd
run 'docker cp as-nonroot:/etc/passwd - | tar -xO'
block port80
run 'docker run -d --name low-port -e PORT=80 shelf:nonroot'
quiet 'sleep 1'
run 'docker logs low-port'
run 'docker run --rm alpine:3.22 cat /proc/sys/net/ipv4/ip_unprivileged_port_start'

put Dockerfile.alpine <<'DF'
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt"]
DF
block alpine-user
run 'docker build -q -f Dockerfile.alpine -t user-demo .'
run 'docker run --rm user-demo'
put ./Dockerfile.alpine <<'DF'
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data && chown app:app /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt && ls -l /data"]
DF
block alpine-fixed
run 'docker build -q -f Dockerfile.alpine -t user-demo .'
run 'docker run --rm user-demo'

block bases
run 'docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "golang|debian|alpine|distroless"'
block packages
run 'docker run --rm debian:trixie sh -c "dpkg -l | grep -c ^ii"'
run 'docker run --rm debian:trixie-slim sh -c "dpkg -l | grep -c ^ii"'
run 'docker run --rm alpine:3.22 grep -c ^P: /lib/apk/db/installed'
run 'docker run --rm debian:trixie-slim sh -c "ls /usr/bin | wc -l"'

put Dockerfile.layers <<'DF'
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50
RUN rm /tmp/download.tar
DF
put Dockerfile.onelayer <<'DF'
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50 && rm /tmp/download.tar
DF
block layers
run 'docker build -q -f Dockerfile.layers -t layers:two .'
run 'docker build -q -f Dockerfile.onelayer -t layers:one .'
run 'docker image ls layers'
run 'docker history layers:two --format "{{.Size}}\t{{.CreatedBy}}" | head -3'
