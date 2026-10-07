#!/usr/bin/env bash
# The terminal sessions quoted in lesson 28 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed:
#
# - Podman 4.9.3 is installed from Ubuntu's own archive by this script, on
#   the host, before the lab starts, if it is not there yet.
# - Ana's ~/.config/containers/registries.conf sends Docker Hub pulls to
#   mirror.gcr.io, for the same rate limit lesson 6 met; the file is shown.
# - The lab cannot give an unprivileged user /dev/net/tun, which rootless
#   Podman's networking needs, so every Podman container here runs with
#   --network none, and the build with --network none; the lesson says so.
#   Podman's warning that "/" is not a shared mount, a property of the lab
#   machine, is filtered out of the transcripts with grep, which the
#   commands show.
# - The images below are pulled before the first command; shelf:1.0.0 is
#   built quietly for Docker from the Dockerfile lesson 15 shows. LXC is described
#   and not run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, containerd 2.3, Podman 4.9,
# TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22"
if [ -z "${IN_LAB:-}" ] && ! command -v podman >/dev/null; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q podman >/dev/null || exit 1
fi
. "$(dirname "$0")/../../capture.sh"
export XDG_RUNTIME_DIR=/tmp/podman-run-$(id -u)
quiet 'mkdir -p "$XDG_RUNTIME_DIR"; podman system reset -f'
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

block layers
run 'docker run -d --name web shelf:1.0.0'
run 'ps -o pid,args -C containerd,containerd-shim-runc-v2 | cut -c1-100'
run 'export CTR="sudo ctr --address /var/run/docker/containerd/containerd.sock"'
run '$CTR namespaces list'
run '$CTR -n moby containers list | cut -c1-90'
run '$CTR -n moby tasks list'
run 'sudo runc --root /run/docker/runtime-runc/moby list | cut -c1-90'
run '$CTR -n moby images list -q | grep -E "shelf|distroless"'

block podman-config
put .config/containers/registries.conf <<'TOML'
[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
TOML

block podman-run
run 'podman --version'
run 'podman run --rm --network none docker.io/library/alpine:3.22 id 2>&1 | grep -v "shared mount"'
run 'podman run --rm --network none docker.io/library/alpine:3.22 cat /proc/self/uid_map 2>&1 | grep -v "shared mount"'
run 'podman run -d --name sleeper --network none docker.io/library/alpine:3.22 sleep 300 2>&1 | grep -v "shared mount"'
run 'ps -o user,pid,args -C sleep'
run 'podman ps --format "{{.Names}} {{.Image}} {{.Status}}" 2>&1 | grep -v "shared mount"'
quiet 'podman rm -f -t 0 sleeper'

block short-name
run 'cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..'
put .config/containers/registries.conf <<'TOML'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
TOML

block podman-build
run 'cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..'
run 'podman run -d --name shelf --network none localhost/shelf:1.0.0 2>&1 | grep -v "shared mount"'
quiet 'sleep 1'
run 'podman logs shelf 2>&1 | grep -v "shared mount"'
quiet 'podman rm -f -t 0 shelf'
run 'podman images --format "{{.Repository}}:{{.Tag}}" 2>&1 | grep -v "shared mount"'
run 'docker images --format "{{.Repository}}:{{.Tag}}" | grep shelf'
