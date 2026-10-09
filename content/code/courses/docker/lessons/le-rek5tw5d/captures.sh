#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and the lesson 18 Dockerfile and probe/main.go are written quietly
# for the Compose section. The `sleep`s are the script's, and stand for the
# moment a person saves a file and looks at the terminal; the prose says how
# long each was. Edits to source files are made with `sed`, shown, where a
# person would use an editor.
#
# No debugger client is attached in the lab: the lesson shows the debugger
# listening and marks attaching an editor as not run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, Compose v5.6, Node 24,
# TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot node:24-alpine"
. "$(dirname "$0")/../../capture.sh"
cd shelf
mkdir -p probe
staged probe/main.go <<'GO'
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
staged Dockerfile <<'DF'
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
staged .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
cd ..

block node-watch
put hello/server.js <<'JS'
const http = require('node:http');

const greeting = 'hello from the container';

http.createServer((req, res) => {
  res.end(greeting + '\n');
}).listen(3000, () => console.log('listening on 3000'));
JS
run 'docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 node:24-alpine node --watch server.js'
quiet 'sleep 2'
run 'curl -s localhost:3000'
run 'sed -i "s/hello from the container/hello again, no rebuild/" hello/server.js'
quiet 'sleep 2'
run 'curl -s localhost:3000'
run 'docker logs hello'
quiet 'docker rm -f hello'

block inspect
run 'docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 -p 127.0.0.1:9229:9229 node:24-alpine node --watch --inspect=0.0.0.0:9229 server.js'
quiet 'sleep 2'
run 'docker logs hello 2>&1 | head -2'
run 'curl -s localhost:9229/json/list | jq ".[] | {title, url, webSocketDebuggerUrl}"'
quiet 'docker rm -f hello'

block go-mount
put shelf/compose.dev.yaml <<'YAML'
services:
  web:
    image: golang:1.25
    working_dir: /src
    command: ["go", "run", "."]
    volumes:
      - .:/src
      - gocache:/root/.cache/go-build
    ports:
      - "127.0.0.1:8080:8080"

volumes:
  gocache:
YAML
run 'cd shelf'
run 'docker compose -f compose.dev.yaml up -d 2>&1 | grep -E "Started|Created"'
quiet 'sleep 25'
run 'curl -s localhost:8080/books | jq length'
run 'sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go'
run 'docker compose -f compose.dev.yaml restart web 2>&1 | grep Started'
quiet 'sleep 15'
run 'curl -s localhost:8080/books | jq -c ".[3]"'
run 'docker compose -f compose.dev.yaml logs web | tail -2'
run 'docker compose -f compose.dev.yaml down -v 2>&1 | grep -c Removed'
run 'git checkout main.go'
run 'cd ..'

block hidden
put shelf/Dockerfile.dev <<'DF'
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o shelf .
CMD ["./shelf"]
DF
run 'cd shelf && docker build -q -f Dockerfile.dev -t shelf:dev . && cd ..'
run 'docker run --rm shelf:dev ls -l /src/shelf'
run 'docker run --rm -v "$PWD/shelf":/src shelf:dev'
run 'docker run --rm -v "$PWD/shelf":/src shelf:dev ls /src | head -3'

block watch
put shelf/compose.yaml <<'YAML'
services:
  web:
    build:
      context: .
      args:
        VERSION: dev
    image: shelf:dev-watch
    ports:
      - "127.0.0.1:8080:8080"
    develop:
      watch:
        - action: rebuild
          path: .
          include:
            - "*.go"
YAML
run 'cd shelf'
run 'docker compose up -d --wait 2>&1 | grep -E "Healthy|Started"'
run 'curl -s localhost:8080/books | jq length'
run 'docker compose watch --no-up > watch.log 2>&1 &'
quiet 'sleep 3'
run 'sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go'
quiet 'sleep 40'
run 'grep -vE "^ *#|^$" watch.log | head -12'
run 'curl -s localhost:8080/books | jq -c ".[3]"'
run 'kill %1'
