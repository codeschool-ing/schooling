#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of azure-compute (lock-in), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-xhf8qsqd/captures.sh
#
# There is no Azure account here and nothing reaches Azure. What runs is the
# shop's image of lesson 7, built once and started three ways: by Docker on
# its own, beside Dapr's sidecar (daprio/daprd:1.17.16) in its network as
# lesson 9 did, and as a pod in a kind cluster as lesson 11 did; and
# exitcost.py, a program of the standard library whose figures are invented.
#
# What is STAGED rather than typed:
#   - app.py and the Dockerfile are taken from lesson 7, `the-shop-at-home`;
#     cluster.yaml, shop-pod.yaml and exitcost.py from this lesson's own text,
#     so the files that ran are the files the student reads;
#   - the image is built FROM this machine's python:3.12-slim, which lab.sh
#     rebuilt with the proxy's certificate added; the student built shop:1.0
#     in lesson 7, from the plain image, and their digest differs from this
#     one, while staying the same in each of the three runs;
#   - kubectl is the one inside kind's node image, run through `docker exec`
#     (lab.sh says how); the student's is the one the `kubernetes` course
#     installed, and talks to the same API server;
#   - the proxy variables of the recording machine are unset before kind runs,
#     so the nodes do not inherit them; kind creates the cluster with --quiet;
#   - the `sleep` lines give a container or a sidecar time to start before the
#     next command asks it something;
#   - the final `quiet` lines only make sure everything is gone if a step
#     failed; the lesson removes it all itself.
#
# Container ids, digests and seconds-up differ on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON7="$HERE/../le-gpjpyeh5/the-shop-at-home.md"
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

DAPRD=daprio/daprd:1.17.16
cleanup() {
  quiet 'docker rm -f shop shop-dapr'
  quiet 'kind delete cluster --name shop'
  quiet 'docker image rm shop:1.0 shop:again'
}
trap cleanup EXIT
cleanup
quiet 'unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy'

mkdir -p shop
from_example "$LESSON7" app.py > shop/app.py
from_lesson "$LESSON7" Dockerfile > shop/Dockerfile
from_lesson "$HERE/portable-seams.md" cluster.yaml > cluster.yaml
from_lesson "$HERE/portable-seams.md" shop-pod.yaml > shop-pod.yaml
from_example "$HERE/what-leaving-costs.md" exitcost.py > exitcost.py

# portable-seams
block store
run "docker info --format '{{.DriverStatus}}'"

block build
run 'docker build --quiet --tag shop:1.0 shop'
run "docker image inspect shop:1.0 --format '{{.Id}}'"
run 'docker build --quiet --tag shop:again shop'
run 'docker image rm shop:again'

block docker
run 'docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null'
quiet 'sleep 1'
run "curl -s -w '\n' localhost:8080/version"
run "docker inspect shop --format '{{.Image}}'"
run 'docker rm -f shop > /dev/null'

block dapr
run 'docker run -d --name shop -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null'
run "docker run -d --name shop-dapr --network container:shop $DAPRD ./daprd --app-id shop --app-port 8080 > /dev/null"
quiet 'sleep 3'
run "curl -s -w '\n' localhost:3500/v1.0/invoke/shop/method/version"
run "docker inspect shop --format '{{.Image}}'"
run 'docker rm -f shop shop-dapr > /dev/null'

block kind
run 'kind create cluster --name shop --config cluster.yaml --quiet'
run 'kind load docker-image shop:1.0 --name shop'
run 'kubectl apply -f shop-pod.yaml'
run 'kubectl wait --for=condition=Ready pod/shop --timeout=120s'
run "kubectl exec shop -- python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/version').read().decode())\""
run "kubectl get pod shop -o jsonpath='{.spec.nodeName} {.status.containerStatuses[0].image}{\"\\n\"}'"
run "kubectl get pod shop -o jsonpath='{.status.containerStatuses[0].imageID}{\"\\n\"}'"
run "docker exec shop-worker ctr -n k8s.io images ls name==docker.io/library/shop:1.0 2> /dev/null | awk '{print \$1, \$3}'"
run 'kind delete cluster --name shop'

# what-leaving-costs
block exitcost
run 'python3 exitcost.py'
