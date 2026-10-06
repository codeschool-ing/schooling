#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 is built quietly from the lesson 14 Dockerfile.
# The `sleep` between starting a container and reading its state is the
# script's, so that there is something to read; the lesson's prose says how
# long each one was. The password in `shelf.env` is a lab value for a database
# that does not exist.
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

block unpublished
run 'docker run -d --name web shelf:1.0.0'
quiet 'sleep 1'
run 'curl -sS localhost:8080/version'
run 'docker port web'
quiet 'docker rm -f web'

block publish-all
run 'docker run -d --name web -p 8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'docker port web'
run 'ss -ltn | grep -E "State|:8080"'
run 'curl -s localhost:8080/version'
quiet 'docker rm -f web'

block publish-local
run 'docker run -d --name web -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'ss -ltn | grep -E "State|:8080"'
run 'docker run -d --name web2 -p 127.0.0.1:8080:8080 shelf:1.0.0'
run 'docker run -d --name web3 -p 127.0.0.1:8081:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'curl -s localhost:8081/version'
quiet 'docker rm -f web web2 web3'

block env-port
run 'docker run -d --name web -e PORT=9090 -p 127.0.0.1:8080:9090 shelf:1.0.0'
quiet 'sleep 1'
run 'docker logs web'
run 'curl -s localhost:8080/version'
quiet 'docker rm -f web'

block env-file
put shelf.env <<'ENV'
PORT=8080
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
ENV
run 'docker run -d --name web --env-file shelf.env shelf:1.0.0'
quiet 'sleep 2'
run 'docker logs web'
run 'docker inspect web --format "{{json .Config.Env}}" | jq .'
quiet 'docker rm -f web'

block no-limits
run 'docker run -d --name web shelf:1.0.0'
quiet 'sleep 1'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"'
quiet 'docker rm -f web'

block memory
run 'docker run -d --name hog --memory 64m alpine:3.22 tail /dev/zero'
quiet 'sleep 4'
run 'docker inspect hog --format "{{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}"'
quiet 'docker rm -f hog'

block cpus
run 'docker run -d --name spin --cpus 0.5 alpine:3.22 sh -c "while :; do :; done"'
run 'docker run -d --name spin-free alpine:3.22 sh -c "while :; do :; done"'
quiet 'sleep 5'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"'
quiet 'docker rm -f spin spin-free'

block shelf-limits
run 'docker run -d --name web --memory 64m --cpus 0.5 --pids-limit 64 -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"'
run 'docker inspect web --format "memory={{.HostConfig.Memory}} nanocpus={{.HostConfig.NanoCpus}} pids={{.HostConfig.PidsLimit}}"'
quiet 'docker rm -f web'

block no-restart
run 'docker run -d --name web --env-file shelf.env shelf:1.0.0'
quiet 'sleep 3'
run 'docker ps -a --format "table {{.Names}}\t{{.Status}}"'
quiet 'docker rm -f web'

block on-failure
run 'docker run -d --name web --restart on-failure:3 --env-file shelf.env shelf:1.0.0'
quiet 'sleep 15'
run 'docker inspect web --format "{{.State.Status}} restarts={{.RestartCount}} exit={{.State.ExitCode}}"'
run 'docker logs web 2>&1 | grep "database:" | cut -c1-47'
quiet 'docker rm -f web'

block unless-stopped
run 'docker run -d --name web --restart unless-stopped -p 127.0.0.1:8080:8080 shelf:1.0.0'
quiet 'sleep 1'
run 'docker stop web'
quiet 'sleep 3'
run 'docker ps -a --format "table {{.Names}}\t{{.Status}}"'
run 'docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"'
run 'docker update --restart no web && docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"'
