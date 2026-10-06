#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and probe/main.go from lesson 18 is written quietly. The failing
# test is made by an edit with `sed`, shown, and undone with `git checkout`,
# shown. Long build logs are cut down with `grep`, which the commands show.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, Compose v5.6, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot postgres:17"
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
cat > .dockerignore <<'IGN'
.git
.env
*.env
compose*.yaml
testdata/
Dockerfile*
.dockerignore
IGN

block same-go
run 'docker run --rm -v "$PWD":/src -w /src golang:1.25 go version'
run 'docker run --rm -v "$PWD":/src -w /src golang:1.25 go test ./...'
run 'docker run --rm -v "$PWD":/src -w /src golang:1.25 go test -race -count=1 ./...'

block test-stage
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

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
DF
run 'docker build --target test . 2>&1 | grep -E "^#[0-9]+ [0-9.]+ (=== RUN|--- |PASS|ok)|\[test" | awk '\''!seen[$0]++'\'''
run 'docker build -t shelf:1.7.0 . 2>&1 | grep -oE "\[(build|test|stage-2) [0-9]+/[0-9]+\]" | sort -u'

block test-fails
run 'sed -i "s/\"ok/\"OK/" main.go && git diff --stat'
run 'docker build --target test . > build.log 2>&1; echo "exit $?"'
run 'grep -E "main_test.go|FAIL" build.log | head -4'
run 'git checkout main.go'

block integration
put compose.test.yaml <<'YAML'
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
run 'docker compose -f compose.test.yaml run --rm tests > it.log 2>&1; echo "exit $?"'
run 'grep -vE "^ *(Container|Network|Volume) " it.log'
run 'docker compose -f compose.test.yaml down 2>&1 | grep -c Removed'

block integration-fails
run 'docker compose -f compose.test.yaml run --rm -e DATABASE_URL=postgres://shelf:wrong@db:5432/shelf tests > it.log 2>&1; echo "exit $?"'
run 'grep -E "^(---|FAIL)|password" it.log | head -4'
run 'docker compose -f compose.test.yaml down 2>&1 | grep -c Removed'
