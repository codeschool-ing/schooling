#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and shelf:1.0.0 and shelf:1.0.1 are built quietly from the Dockerfile
# lesson 15 shows, so that the machine has a little history to look at: a few
# containers, one of them exited, a volume nobody uses and some build cache.
# Those commands are the block finding-things.md shows, read out of it.
# The `sleep`s are the script's.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22 postgres:17"
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
cd ..
# the history, made by the block finding-things.md gives the student
history=$(python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-mywwhq09/finding-things.md" 'cd ~/shelf') || exit 1
quiet "$history"

block ps-filters
run 'docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
run 'docker ps -a --filter status=exited --format "{{.Names}}"'
run 'docker ps --filter ancestor=shelf:1.0.0 --format "{{.Names}}"'
run 'docker ps -q'

block inspect-format
run 'docker inspect web --format "{{.State.Status}} since {{.State.StartedAt}}"'
run 'docker inspect web --format "{{json .NetworkSettings.Ports}}" | jq -c'
run 'docker inspect web --format "{{.Config.User}} {{json .Config.Cmd}}"'

block logs
run 'docker logs --timestamps --tail 2 web'
run 'docker logs --since 1h web | wc -l'
run 'docker logs --since 1h web 2>&1 | wc -l'

block no-shell
run 'docker exec web sh'

block outside
run 'docker top web -o pid,user,args'
run 'docker diff web'
run 'docker cp web:/shelf ./shelf-from-container && ls -l shelf-from-container'
run 'docker run --rm --network container:web alpine:3.22 wget -qO- localhost:8080/health'
run 'docker run --rm --pid container:web alpine:3.22 ps -o pid,user,args'

block df
run 'docker system df'

block prune-containers
run 'docker container prune -f'
run 'docker image ls --format "{{.Repository}}:{{.Tag}}" | sort'

block prune-images
run 'docker rm -f web-old >/dev/null; docker image rm shelf:1.0.0'
run 'docker image prune -f'

block prune-volumes
run 'docker volume ls --format "{{.Name}}"'
run 'docker volume prune -f'
run 'docker volume prune -af'

block prune-builder
run 'docker builder prune -f | tail -1'
run 'docker builder prune -af | tail -1'
run 'docker system df'
