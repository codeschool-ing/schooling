#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of gcp-operations.
#
#   bash captures.sh     # after lesson 1's captures, which leave ~/gcp/shop
#
# The registry is the open-source Distribution registry, run as a container
# on localhost:5000: it stands in for Artifact Registry's Docker API, which it
# shares, and for nothing else (no immutability, no scanning, no cleanup).
# STAGED: the second version of app.py is written with sed, as the lesson
# says; the lesson shows the line it adds.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp/shop" || exit 1
docker rm -f registry > /dev/null 2>&1
from_lesson "$HERE/../le-01vpqvde/the-build.md" shop/api/app.py > api/app.py

block registry
run 'docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0'
sleep 2
run 'curl -s localhost:5000/v2/_catalog; echo'

block push-v1
quiet 'docker build -q -t localhost:5000/shop/api:v1 api'
run 'docker push -q localhost:5000/shop/api:v1'
run "docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1"
D1=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1 | cut -d@ -f2)

block push-again
sed -i 's|    {"id": "p-002", "name": "Pencil case", "price_cents": 1890},|&\n    {"id": "p-003", "name": "Eraser", "price_cents": 390},|' api/app.py
run 'grep -c price_cents api/app.py'
quiet 'docker build -q -t localhost:5000/shop/api:v1 api'
run 'docker push -q localhost:5000/shop/api:v1'
run "docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1"
run 'curl -s localhost:5000/v2/shop/api/tags/list; echo'

block by-digest
quiet 'docker image rm localhost:5000/shop/api:v1'
quiet "docker image rm localhost:5000/shop/api@$D1"
run "docker pull -q localhost:5000/shop/api@$D1"
run "docker run --rm -d --name api -p 8080:8080 localhost:5000/shop/api@$D1"
sleep 2
run 'curl -s localhost:8080/products; echo'
quiet 'docker rm -f api'
quiet 'docker rm -f registry'
