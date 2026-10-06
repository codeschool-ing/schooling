#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command; the lesson 18 Dockerfile and probe/main.go are written quietly, and
# shelf:1.5.0 is built from them before the first section. The `sleep` between
# starting something and reading its state is the script's; the prose says how
# long each one was. The password is a lab value.
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
quiet 'docker build -q --build-arg VERSION=1.5.0 -t shelf:1.5.0 .'

block by-hand
run 'docker network create shelfnet'
run 'docker run -d --name db --network shelfnet -e POSTGRES_USER=shelf -e POSTGRES_PASSWORD=lab-only-secret -e POSTGRES_DB=shelf postgres:17'
run 'docker run -d --name web --network shelfnet -p 127.0.0.1:8080:8080 -e DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf shelf:1.5.0'
quiet 'sleep 2'
run 'docker logs web'
quiet 'sleep 5'
run 'docker start web'
quiet 'sleep 1'
run 'curl -s localhost:8080/books | jq -c ".[]"'
quiet 'docker rm -f web db; docker network rm shelfnet; docker volume prune -af'

block files
put compose.yaml <<'YAML'
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_DB: shelf
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      timeout: 2s
      retries: 15
    restart: unless-stopped

  web:
    build:
      context: .
      args:
        VERSION: 1.5.0
    image: shelf:1.5.0
    env_file: shelf.env
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  db-data:

secrets:
  db_password:
    file: ./db_password.txt
YAML
put shelf.env <<'ENV'
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
ENV
put db_password.txt <<'TXT'
lab-only-secret
TXT
put .dockerignore <<'IGN'
.git
.env
*.env
db_password.txt
compose.yaml
testdata/
Dockerfile*
.dockerignore
IGN
run 'ls -l compose.yaml shelf.env db_password.txt'

block up
run 'docker compose up -d'
run 'docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"'
run 'curl -s localhost:8080/books | jq -c ".[]"'
run 'docker compose logs web'

block where-password
run 'docker compose exec db ls -l /run/secrets/'
run 'docker inspect shelf-db-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"POSTGRES\"))"'
run 'docker inspect shelf-web-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"DATABASE\"))"'

block what-it-made
run 'docker network ls --filter name=shelf --format "{{.Name}}\t{{.Driver}}"'
run 'docker volume ls --filter name=shelf --format "{{.Name}}"'
run 'docker ps --format "table {{.Names}}\t{{.Image}}"'

block exec
run 'docker compose exec db psql -U shelf -c "INSERT INTO books (title, author) VALUES ('"'"'Grande Sertão: Veredas'"'"', '"'"'João Guimarães Rosa'"'"')"'
run 'curl -s localhost:8080/books | jq -c ".[]"'

block down-up
run 'docker compose down'
run 'docker volume ls --filter name=shelf --format "{{.Name}}"'
run 'docker compose up -d --wait'
run 'curl -s localhost:8080/books | jq length'

block rebuild
run 'sed -i "s/VERSION: 1.5.0/VERSION: 1.5.1/; s/image: shelf:1.5.0/image: shelf:1.5.1/" compose.yaml'
run 'docker compose up -d --build --wait 2>&1 | grep -vE "^ *#|^$"'
run 'curl -s localhost:8080/version'
run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'

block down-v
run 'docker compose down -v'
run 'docker volume ls --filter name=shelf --format "{{.Name}}"; docker network ls --filter name=shelf --format "{{.Name}}"'
