#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 is built quietly from the Dockerfile lesson 15 shows. The
# `sleep`s are the script's. The containers' addresses are whatever the daemon
# handed out on the day; the lesson quotes them as they came.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22"
. "$(dirname "$0")/../../capture.sh"
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
quiet 'docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .'
cd ..

block networks
run 'docker network ls'
run 'ip -brief addr show docker0'

block veth
run 'docker run -d --name box-a alpine:3.22 sleep 600'
run 'ip -brief link | grep -E "^(docker0|veth)"'
run 'docker exec box-a ip addr show eth0'
run 'docker exec box-a ip route'

block default-bridge
run 'docker run -d --name box-b alpine:3.22 sleep 600'
run 'docker exec box-b ping -c 1 -W 1 box-a'
run 'docker exec box-b ping -c 1 -W 1 $(docker inspect box-a --format "{{.NetworkSettings.Networks.bridge.IPAddress}}")'

block user-network
run 'docker network create shelfnet'
run 'docker run -d --name shelf-web --network shelfnet shelf:1.0.0'
run 'docker run -d --name box-c --network shelfnet alpine:3.22 sleep 600'
quiet 'sleep 1'
run 'docker exec box-c wget -qO- shelf-web:8080/version'
run 'docker exec box-c cat /etc/resolv.conf'
run 'docker exec box-c nslookup shelf-web'

block isolation
run 'docker exec box-a wget -qO- -T 2 shelf-web:8080/version'
run 'docker exec box-a wget -qO- -T 2 $(docker inspect shelf-web --format "{{.NetworkSettings.Networks.shelfnet.IPAddress}}"):8080/version'
run 'docker network connect shelfnet box-a'
run 'docker exec box-a wget -qO- -T 2 shelf-web:8080/version'

block localhost
run 'docker run -d --name host-shelf -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'curl -s localhost:8080/version'
run 'docker exec box-c wget -qO- -T 2 localhost:8080/version'
run 'docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8080/version'
run 'docker run --rm -p 8081:8080 -d --name pub shelf:1.0.0 >/dev/null; sleep 1; docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8081/version'
quiet 'docker rm -f pub host-shelf'

block host-network
run 'docker run -d --name hostnet --network host -e PORT=9090 shelf:1.0.0'
quiet 'sleep 1'
run 'ss -ltn | grep -E "State|:9090"'
run 'curl -s localhost:9090/version'
run 'docker inspect hostnet --format "{{json .NetworkSettings.Networks}}" | jq -c "keys"'
quiet 'docker rm -f hostnet'

block none
run 'docker run --rm --network none alpine:3.22 ip -o link'
