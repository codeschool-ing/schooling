#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/twelve are EXTRACTED from the section "A catalogue
# written to the factors" (the-catalogue.md), as the copy button hands them
# over. Staged: the image is built beforehand (lab.sh, "prebuild"), so the
# `pip install` layer is found in the cache. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-chyy9qxw
lab reset
quiet 'docker image rm -f quitanda/catalogue:dev quitanda/catalogue:1.0.0'
at '~/lab/twelve'
for f in catalogue.py requirements.txt Dockerfile compose.yaml; do save $L/the-catalogue.md $f "~/lab/twelve/$f"; done
prebuild
block up
run 'docker compose build --quiet'
run 'docker compose run --rm catalogue python catalogue.py migrate'
run 'docker compose up -d'
block freeze
run 'docker compose exec catalogue pip freeze'
block products
run 'curl -s localhost:8000/products'
block env
run 'docker compose exec catalogue printenv DATABASE_URL PORT'
block no-config
run 'docker compose run --rm -e DATABASE_URL= catalogue; echo "exit code $?"'
block other-db
run 'docker run -d --name other-db --network twelve_default -e POSTGRES_USER=quitanda -e POSTGRES_PASSWORD=quitanda postgres:17'
sleep 6
run 'DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose up -d catalogue'
sleep 2
run 'docker compose port catalogue 8000'
P=$(lab as "cd ~/lab/twelve && docker compose port catalogue 8000")
run "curl -sS $P/products"
block other-db-migrated
run 'DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose run --rm catalogue python catalogue.py migrate'
run "curl -s $P/products"
block other-db-gone
run 'docker compose up -d catalogue'
run 'docker rm -f other-db'
sleep 2
run 'docker compose port catalogue 8000'
P=$(lab as "cd ~/lab/twelve && docker compose port catalogue 8000")
run "curl -s $P/products"
block tags
run 'docker tag quitanda/catalogue:dev quitanda/catalogue:1.0.0'
run 'docker image ls quitanda/catalogue'
block release
run 'TAG=1.0.0 docker compose up -d catalogue'
run 'docker compose ps catalogue --format "{{.Name}} {{.Image}} {{.Status}}"'
block scale
run 'docker compose up -d --scale catalogue=3'
run 'docker compose ps catalogue --format "{{.Name}} {{.Ports}}"'
sleep 1
block hits
for p in 8000 8001 8002 8000 8000; do run "curl -s localhost:$p/hits"; done
run 'curl -s localhost:8001/products'
block stop-fast
run 'time docker compose stop catalogue'
run 'docker compose logs catalogue | grep -E "SIGTERM|stopped"'
block stop-slow
run 'docker run -d --name sleeper python:3.12-slim python -c "import time; time.sleep(3600)"'
run 'time docker stop sleeper'
run 'docker inspect --format "{{.State.ExitCode}}" sleeper'
quiet 'docker rm sleeper'
block logs
run 'docker compose logs catalogue --no-log-prefix | grep GET'
block admin
run 'docker compose exec db psql -U quitanda -c "SELECT sku, price_cents FROM products ORDER BY price_cents DESC LIMIT 3"'
quiet 'docker compose down -v'
