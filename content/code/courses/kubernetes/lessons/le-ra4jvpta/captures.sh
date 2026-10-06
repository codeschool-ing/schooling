#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# This lesson builds its clusters by hand, with kind, rather than through
# `fresh`. The images are already on the laptop (lab.sh tools pulled them).
#
# What is STAGED rather than typed:
#   - "Docker is not running" is produced by pointing the client at a socket
#     nothing listens on (DOCKER_HOST), which is exactly what the client sees
#     when the daemon is stopped; stopping the real daemon would stop every
#     other cluster on the machine.
#   - "the port is taken" is a small web server started beforehand on 8080.
# The memory and CPU figures from `docker stats` differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
lab down

block versions
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'
run 'kind version'
run 'kubectl version --client'
block create
put cluster.yaml <<'CODE'
# A study cluster: one control-plane node and two workers.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
- role: worker
CODE
run 'time kind create cluster --name study --config cluster.yaml --quiet'
run 'kind get clusters'
run 'kubectl config current-context'
quiet 'kubectl wait --for=condition=Ready nodes --all --timeout=180s'
run 'kubectl get nodes -o wide'
block containers
run 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
quiet 'sleep 20'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"'
block fail-name
run 'kind create cluster --name study --config cluster.yaml'
block fail-docker
run 'DOCKER_HOST=unix:///run/nothing.sock kind create cluster --name other 2>&1 | tail -n 1'
block fail-port
quiet '(setsid python3 -m http.server 8080 --bind 0.0.0.0 >/dev/null 2>&1 </dev/null &); sleep 1'
put ports.yaml <<'CODE'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
CODE
run 'kind create cluster --name ports --config ports.yaml 2>&1 | grep -o "Bind for .*"'
quiet 'pkill -f "http.server 8080"'
quiet 'kind delete cluster --name ports'
block fail-context
run 'kind delete cluster --name study'
run 'kubectl get nodes'
run 'kubectl config current-context'
