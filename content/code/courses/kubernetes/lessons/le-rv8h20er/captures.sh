#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# This lesson is the student's setup and then the shop on Docker Compose, on
# one machine, which is what the course starts from. It ends by building the
# cluster every later lesson starts from. Container ids, image ids and the
# uptime Docker prints differ on every run.
#
# EVERY FILE THE LESSON SHOWS IS THE FILE THIS RUNS. main.go, the Dockerfile,
# build.sh, cluster.yaml and up.sh are read out of the lesson's own sections
# with `shown`, so the page and the capture cannot drift apart; lab.sh builds
# the shop's images from the same sections.
#
# What is STAGED rather than typed: removing whatever an earlier run left
# (`docker compose down`, the kind and kubectl the previous run installed,
# the shop's images and Docker's build cache, the cluster), writing each file
# the student copies from the page, the pauses between commands, which give
# the restart policy and the kubelet time to act, and a user `bruno` who is
# not in the docker group. The downloads go through the recording machine's
# proxy (`online`); nothing else does.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

L=$(cd "$(dirname "$0")" && pwd)
. "$L/../../capture.sh"
export PATH=/usr/local/bin:$PATH
quiet 'docker compose down --remove-orphans'
quiet 'docker rm -f try'
quiet 'kind delete cluster --name shop'
quiet 'rm -f /usr/local/bin/kind /usr/local/bin/kubectl'

block your-machine
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'
online
run 'ARCH=$(dpkg --print-architecture); echo $ARCH'
run 'curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH'
run 'curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check'
run 'curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl'
run 'echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check'
offline
run 'sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl'
hash -r
run 'kind version'
run 'kubectl version --client'

block the-shop
shown "$L/the-shop.md" main.go >main.go || exit 1
shown "$L/the-shop.md" Dockerfile >Dockerfile || exit 1
shown "$L/the-shop.md" build.sh >build.sh || exit 1
quiet 'docker rmi shop:1.0 shop:1.1 shop:2.0'
quiet 'docker builder prune -af'
run 'chmod +x build.sh'
run 'time ./build.sh'
run 'docker images shop'
run 'docker run -d --rm --name try -p 8080:8080 shop:1.1'
quiet 'sleep 1'
run 'curl -s localhost:8080'
run 'docker stop try'

block one-host
put compose.yaml <<'CODE'
services:
  web:
    image: shop:1.0
    ports:
      - "8080:8080"
    restart: always
CODE
run 'docker compose up -d'
quiet 'sleep 2'
run 'curl -s localhost:8080'
run 'docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"'
run 'sudo kill -9 $(docker inspect -f "{{.State.Pid}}" shop-web-1)'
quiet 'sleep 3'
run 'docker inspect -f "{{.RestartCount}} restart(s), running: {{.State.Running}}" shop-web-1'
run 'docker compose up -d --scale web=3'
quiet 'docker compose up -d --scale web=1'

block the-update
put probe.sh <<'CODE'
#!/bin/sh
# Ask the shop 300 times, 20 ms apart, and print each answer's status code.
# 000 means curl got no answer at all.
for i in $(seq 300); do
  curl -s -o /dev/null -m 1 -w '%{http_code}\n' localhost:8080
  sleep 0.02
done
CODE
quiet 'chmod +x probe.sh'
run 'sed -i "s/shop:1.0/shop:1.1/" compose.yaml'
run './probe.sh > codes.txt & docker compose up -d; wait'
run 'sort codes.txt | uniq -c'
run 'curl -s localhost:8080'
quiet 'docker compose down'

block the-cluster
shown "$L/a-cluster-of-your-own.md" cluster.yaml >cluster.yaml || exit 1
shown "$L/a-cluster-of-your-own.md" up.sh >up.sh || exit 1
run 'chmod +x up.sh'
run './up.sh'
run 'kubectl get nodes'

block not-loaded
run 'docker tag shop:1.0 shop:dev'
run 'kubectl create deployment dev --image=shop:dev'
quiet 'sleep 25'
run 'kubectl get pods -l app=dev'
run 'kubectl describe pods -l app=dev | grep -m 1 "Failed to pull"'
run 'kind load docker-image shop:dev --name shop'
run 'kubectl delete pods -l app=dev'
quiet 'kubectl rollout status deployment/dev --timeout=60s'
run 'kubectl get pods -l app=dev'
quiet 'kubectl delete deployment dev'

block no-group
quiet 'id bruno || useradd -m bruno'
run 'sudo -u bruno docker ps'
run 'sudo -u bruno kind get clusters'
