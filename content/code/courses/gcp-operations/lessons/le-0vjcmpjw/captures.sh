#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of gcp-operations.
#
#   bash captures.sh     # after lesson 1's captures, which leave ~/gcp/shop
#
# NOTHING HERE IS CLOUD DEPLOY. The two "environments" are two containers of
# the same image on ports 8081 (dev) and 8082 (prod), started by hand, to show
# the one property a promotion has: the image does not change on the way.
# The registry is the local Distribution registry of lesson 2.
# STAGED: the image a1b2c3d is built and pushed quietly before the first
# block, standing for the build of lesson 1; the lesson says it is there.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp/shop" || exit 1
docker rm -f registry dev prod > /dev/null 2>&1
from_lesson "$HERE/../le-01vpqvde/the-build.md" shop/api/app.py > api/app.py
docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0 > /dev/null
sleep 2
quiet 'docker build -q -t localhost:5000/shop/api:a1b2c3d api'
quiet 'docker push -q localhost:5000/shop/api:a1b2c3d'
quiet 'docker image rm localhost:5000/shop/api:a1b2c3d'

block release
run 'docker pull -q localhost:5000/shop/api:a1b2c3d'
run "docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:a1b2c3d"
D=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:a1b2c3d)

block dev
run "docker run -d --rm --name dev -p 8081:8080 $D"
sleep 2
run 'curl -s localhost:8081/healthz; echo'

block promote
run "docker run -d --rm --name prod -p 8082:8080 $D"
sleep 2
run "docker inspect --format '{{.Name}} {{.Image}}' dev prod"
run 'curl -s localhost:8082/healthz; echo'
quiet 'docker rm -f dev prod registry'
