#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of docker, as a script that
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
# - The images below are pulled before the first command. probe/main.go
#   (lesson 18) and compose.test.yaml (lesson 25) are written quietly, and a
#   registry:3 is started on 127.0.0.1:5000 without a password; it stands in
#   for GHCR, which the lab cannot reach.
# - The pipeline's scan runs Trivy offline, against the database fetched by
#   lesson 20's captures.sh (/opt/docker-lab/trivy-cache), which this script
#   fetches the same way if it is missing. TRIVY_CACHE and TRIVY_FLAGS, set on
#   the command line that runs the pipeline, are how the lab says so; in CI
#   neither is set and Trivy downloads its own.
# - The x/text update reuses lesson 20's module cache (/opt/docker-lab/gopath),
#   with GOPROXY=off, which the command shows.
# - The GitHub Actions workflow is written and shown, and NOT run: the lab has
#   no GitHub. The lesson says so.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, Compose v5.6, Trivy 0.75,
# TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot postgres:17 registry:3 aquasec/trivy:0.75.0"
if [ -z "${IN_LAB:-}" ] && [ ! -s /opt/docker-lab/trivy-cache/db/trivy.db ]; then
  m=$(curl -fsS -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    https://mirror.gcr.io/v2/aquasec/trivy-db/manifests/2) || exit 1
  d=$(printf '%s' "$m" | jq -r '.layers[0].digest')
  sudo mkdir -p /opt/docker-lab/trivy-cache/db
  curl -fsSL "https://mirror.gcr.io/v2/aquasec/trivy-db/blobs/$d" -o /tmp/trivy-db.tgz || exit 1
  [ "sha256:$(sha256sum /tmp/trivy-db.tgz | cut -d' ' -f1)" = "$d" ] || { echo "digest mismatch" >&2; exit 1; }
  sudo tar -xzf /tmp/trivy-db.tgz -C /opt/docker-lab/trivy-cache/db && rm /tmp/trivy-db.tgz
fi
if [ -z "${IN_LAB:-}" ] && [ ! -d /opt/docker-lab/gopath/pkg/mod/golang.org/x/text@v0.39.0 ]; then
  echo "run lesson 20's captures.sh first: it prepares the module cache" >&2; exit 1
fi
. "$(dirname "$0")/../../capture.sh"
quiet 'cp -r /opt/docker-lab/trivy-cache ~/trivy-cache'
quiet 'cp -r /opt/docker-lab/gopath/pkg ~/gopkg'
quiet 'docker run -d --name registry -p 127.0.0.1:5000:5000 registry:3'
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
cat > compose.test.yaml <<'YAML'
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_PASSWORD: test-only
      POSTGRES_DB: shelf
    tmpfs:
      - /var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      retries: 15

  tests:
    image: golang:1.25
    working_dir: /src
    volumes:
      - .:/src
    environment:
      DATABASE_URL: postgres://shelf:test-only@db:5432/shelf
    command: ["go", "test", "-tags", "integration", "-count=1", "-v", "./..."]
    depends_on:
      db:
        condition: service_healthy
YAML
cat > .dockerignore <<'IGN'
.git
.github
.env
*.env
*.log
*.tar
build.json
ci/
compose*.yaml
testdata/
Dockerfile*
.dockerignore
IGN

block dockerfile
put Dockerfile <<'DF'
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/probe ./probe

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
DF

block pipeline
put ci/pipeline.sh <<'SH'
#!/bin/sh
# Tests, scans, builds and publishes shelf. The CI workflow runs exactly this,
# and so can anybody with Docker and a registry to push to.
set -eu

: "${REGISTRY:?set REGISTRY, for example ghcr.io/ana}"
REF_NAME=${REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}
REV=$(git rev-parse --short HEAD)
IMAGE=$REGISTRY/shelf

echo "--- unit tests"
docker build --target test --quiet . > /dev/null

echo "--- integration tests"
status=0
docker compose -f compose.test.yaml run --rm tests > integration.log 2>&1 || status=$?
docker compose -f compose.test.yaml down > /dev/null 2>&1
if [ "$status" -ne 0 ]; then cat integration.log; exit "$status"; fi

echo "--- scan"
docker build --quiet -t shelf:ci . > /dev/null
docker save shelf:ci -o shelf-ci.tar
docker run --rm -v "$PWD":/work -w /work ${TRIVY_CACHE:+-v "$TRIVY_CACHE":/cache} \
  aquasec/trivy:0.75.0 image --input shelf-ci.tar --scanners vuln --quiet \
  --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed \
  ${TRIVY_CACHE:+--cache-dir /cache} ${TRIVY_FLAGS:-}

echo "--- build and push"
case $REF_NAME in
  v*.*.*) version=${REF_NAME#v}
          tags="-t $IMAGE:$version -t $IMAGE:${version%.*} -t $IMAGE:${version%%.*}" ;;
  *)      version=dev
          tags="-t $IMAGE:$REF_NAME" ;;
esac
docker build --platform linux/amd64,linux/arm64 --build-arg VERSION="$version" \
  --cache-from "type=registry,ref=$IMAGE:buildcache" \
  --cache-to "type=registry,ref=$IMAGE:buildcache,mode=max" \
  --sbom=true --provenance=mode=min --metadata-file build.json \
  -t "$IMAGE:sha-$REV" $tags --push . > build.log 2>&1 || { tail -20 build.log; exit 1; }

digest=$(jq -r '."containerimage.digest"' build.json)
echo "pushed $IMAGE@$digest"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "digest=$digest" >> "$GITHUB_OUTPUT"
fi
SH

block workflow
put .github/workflows/image.yml <<'YAML'
name: image

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]

permissions:
  contents: read
  packages: write

jobs:
  image:
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.pipeline.outputs.digest }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Use the containerd image store, which multi-platform builds need
        run: |
          f=/etc/docker/daemon.json
          { sudo cat "$f" 2>/dev/null || echo '{}'; } \
            | jq '.features["containerd-snapshotter"] = true' > daemon.json
          sudo mv daemon.json "$f" && sudo systemctl restart docker

      - name: Log in to GHCR with this job's own token
        run: echo "$TOKEN" | docker login ghcr.io -u "${{ github.actor }}" --password-stdin
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - id: pipeline
        run: sh ci/pipeline.sh
        env:
          REGISTRY: ghcr.io/${{ github.repository_owner }}
          REF_NAME: ${{ github.ref_name }}

      - name: Log out
        if: always()
        run: docker logout ghcr.io
YAML

block first-run
run 'git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "ci: one pipeline, run anywhere" && git log --oneline -1'
run 'REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"'

block fix
run 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"'
run 'git -c user.name=Ana -c user.email=ana@example.com commit -qam "deps: golang.org/x/text v0.39.0" && git log --oneline -1'

block second-run
run 'REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"'
run 'curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags'

block release
run 'git tag v1.8.0'
run 'docker builder prune -af | tail -1'
run 'REF_NAME=v1.8.0 REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"'
run 'grep -cE "^#[0-9]+ CACHED" build.log'
run 'curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags'

block platforms
run 'docker buildx imagetools inspect localhost:5000/shelf:1.8.0 | grep -E "Platform"'
run 'docker buildx imagetools inspect localhost:5000/shelf:1.8.0 --format "{{json .Provenance}}" | jq -c keys'
