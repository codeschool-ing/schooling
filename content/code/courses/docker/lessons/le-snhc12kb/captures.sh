#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 is built quietly from the lesson 14 Dockerfile. The
# daemon's configuration is NOT changed: user namespace remapping is described
# in the lesson and marked as not run there.
#
# Everything here is done to Ana's own lab, as its owner, to see what each
# default allows and how to take it away. The container given the Docker socket
# runs `docker ps` and nothing else.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22 postgres:17 docker:29.8.2-cli"
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

block caps-default
run 'docker run --rm alpine:3.22 grep CapEff /proc/self/status'
run 'capsh --decode=00000000a80425fb'
run 'grep CapEff /proc/self/status'

block cap-drop
run 'docker run --rm alpine:3.22 chown nobody /tmp && echo "chown worked"'
run 'docker run --rm --cap-drop ALL alpine:3.22 chown nobody /tmp'
run 'docker run --rm --cap-drop ALL alpine:3.22 grep CapEff /proc/self/status'

block shelf-no-caps
run 'docker run -d --name web --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'curl -s localhost:8080/version'
run 'docker inspect web --format "caps dropped: {{.HostConfig.CapDrop}}  options: {{.HostConfig.SecurityOpt}}"'
quiet 'docker rm -f web'

block privileged
run 'docker run --rm alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"'
run 'docker run --rm --privileged alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"'

block socket
run 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker:29.8.2-cli docker ps --format "{{.Names}} {{.Image}}"'

block audit
run 'docker run -d --name ok shelf:1.0.0 >/dev/null; docker run -d --name risky --privileged -v /var/run/docker.sock:/var/run/docker.sock alpine:3.22 sleep 300 >/dev/null'
put audit.sh <<'SH'
#!/bin/sh
# Lists every running container that holds more than a container should.
docker ps -q | xargs docker inspect --format \
  '{{.Name}} privileged={{.HostConfig.Privileged}} caps={{.HostConfig.CapAdd}}{{range .Mounts}}{{if eq .Source "/var/run/docker.sock"}} DOCKER-SOCKET{{end}}{{end}}'
SH
run 'sh audit.sh'
quiet 'docker rm -f ok risky'

block read-only
run 'docker run --rm --read-only alpine:3.22 touch /etc/oops'
run 'docker run --rm --read-only --tmpfs /tmp alpine:3.22 sh -c "touch /tmp/scratch && ls /tmp && grep \" /tmp \" /proc/mounts"'
run 'docker run -d --name web --read-only --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'curl -s localhost:8080/books | jq length'
quiet 'docker rm -f web'

block postgres-ro
run 'docker run -d --name db --read-only -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17'
quiet 'sleep 4'
run 'docker logs db 2>&1 | grep -i "read-only" | head -3'
quiet 'docker rm -f db; docker volume rm pgdata'
run 'docker run -d --name db --read-only --tmpfs /var/run/postgresql --tmpfs /tmp -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17'
quiet 'sleep 8'
run 'docker exec db pg_isready -h 127.0.0.1'
