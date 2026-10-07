#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the three base images are pulled before the
# first command; the Dockerfiles and the .dockerignore are written by `put`.
# The arm64 variant of distroless is fetched by the multi-platform build
# itself. The lab machine has no emulator for other processors (lesson 2),
# which is why the arm64 image is built and not run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, BuildKit, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:latest alpine:3.22"
. "$(dirname "$0")/../../capture.sh"
cd shelf

put .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
put Dockerfile.single <<'DF'
FROM golang:1.25
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
DF
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
block build-both
run 'docker build -q -f Dockerfile.single -t shelf:single .'
run 'docker build -q -t shelf:slim .'
block sizes
run 'docker image ls shelf'
block run-slim
run 'docker run -d --name slim -p 127.0.0.1:8080:8080 shelf:slim'
quiet 'sleep 1'
run 'curl -s localhost:8080/health'
run 'docker exec slim sh'
run 'docker exec slim ls /'
block history-slim
run 'docker history shelf:slim'

put Dockerfile.scratch <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN go build -o /out/shelf .

FROM scratch
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
DF
block cgo
run 'docker build -q -f Dockerfile.scratch -t shelf:scratch .'
run 'docker run --rm shelf:scratch'
block cgo-why
run 'docker build -q -f Dockerfile.scratch --target build -t shelf:build-stage .'
run 'docker run --rm shelf:build-stage ldd /out/shelf'
block cgo-fixed
run 'sed -i "s/RUN go build -o/RUN CGO_ENABLED=0 go build -o/" Dockerfile.scratch'
run 'docker build -q -f Dockerfile.scratch -t shelf:scratch .'
run 'docker run --rm -d --name scratch shelf:scratch'
quiet 'sleep 1'
run 'docker logs scratch'
run 'docker image ls shelf:scratch'

block target-test
run 'docker build -q --target build -t shelf:build .'
run 'docker run --rm shelf:build go test ./...'

put ./Dockerfile <<'DF'
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
DF
block multi
run 'docker build -q --platform linux/amd64,linux/arm64 -t shelf:multi .'
run 'docker image ls --tree shelf:multi'
block multi-run
run 'docker run --rm -d --name multi-amd64 shelf:multi'
quiet 'sleep 1'
run 'docker logs multi-amd64'
run 'docker run --rm --platform linux/arm64 shelf:multi'
