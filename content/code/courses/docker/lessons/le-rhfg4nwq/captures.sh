#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 and shelf:1.0.1 are built quietly from the lesson 18
# Dockerfile, with its health check. The swarm has ONE node, Ana's machine:
# the lab has no second one, and the lesson says what changes with more. The
# `sleep`s are the script's, waiting for the swarm to converge; the prose says
# how long. lab.sh leaves the swarm at the start of every run.
#
# The lab's kernel has no IPVS, which Swarm uses for a service's virtual IP and
# for the routing mesh behind a published port; the lesson shows the check.
# So the services here are reached on an overlay network with
# --endpoint-mode dnsrr, from a throwaway Alpine container, and no port is
# published. The lesson says what a normal kernel adds.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22"
. "$(dirname "$0")/../../capture.sh"
cd shelf
mkdir -p probe
cat > probe/main.go <<'GO'
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
cat > Dockerfile <<'DF'
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
cat > .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
quiet 'docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .'
quiet 'docker build -q --build-arg VERSION=1.0.1 -t shelf:1.0.1 .'
cd ..

block init
run 'docker swarm init --advertise-addr 127.0.0.1 | head -2'
run 'docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}"'

block service
run 'ls /proc/net/ip_vs'
run 'docker network create --driver overlay --attachable shopnet'
run 'docker service create --name shelf --replicas 3 --network shopnet --endpoint-mode dnsrr --detach shelf:1.0.0'
quiet 'sleep 15'
run 'docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"'
run 'docker service ps shelf --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"'
run 'docker run --rm --network shopnet alpine:3.22 nslookup shelf | grep Address | sort'
run 'docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version'

block heal
run 'docker kill $(docker ps -q --filter name=shelf.2) > /dev/null'
quiet 'sleep 15'
run 'docker service ps shelf --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}"'
run 'docker service ls --format "table {{.Name}}\t{{.Replicas}}"'

block update
run 'docker service update --image shelf:1.0.1 --update-parallelism 1 --update-delay 5s --detach shelf'
quiet 'sleep 8'
run 'docker service ps shelf --filter desired-state=running --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"'
quiet 'sleep 40'
run 'docker service ps shelf --filter desired-state=running --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"'
run 'docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version'

block rollback
run 'docker service rollback --detach shelf'
quiet 'sleep 45'
run 'docker service inspect shelf --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"'
run 'docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version'
quiet 'docker service rm shelf; sleep 5'

block stack
put shelf/stack.yaml <<'YAML'
services:
  web:
    image: shelf:1.0.1
    networks:
      - shopnet
    deploy:
      replicas: 2
      endpoint_mode: dnsrr
      update_config:
        parallelism: 1
        delay: 5s
        failure_action: rollback
      resources:
        limits:
          memory: 64M

networks:
  shopnet:
    external: true
YAML
run 'docker stack deploy -c shelf/stack.yaml --detach=true shop 2>&1'
quiet 'sleep 15'
run 'docker stack services shop --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"'
run 'docker run --rm --network shopnet alpine:3.22 wget -qO- shop_web:8080/version'
run 'docker stack rm shop'
quiet 'sleep 5'
run 'docker swarm leave --force'
