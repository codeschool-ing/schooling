#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Needs istioctl 1.30.5 and the linkerd CLI edge-26.9.3 on the PATH, both
# downloaded from their projects' release pages. Linkerd is NOT installed in
# the cluster: the machine this was recorded on could not pull Linkerd's
# images, so the lesson shows what its CLI renders, offline, and says so.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset mesh`; the promq helper from lesson 5;
# compose.override.yaml and
# k8s/mesh.yaml, whose contents the lesson shows; simulated customers, five
# requests a second, started in the background; twenty more checkouts sent
# through Envoy before its counters are read; payments told to fail every
# tenth charge and later to wait 2500 ms; the kind cluster, created by
# `lab.sh kind-up`, with Istio's two images copied into it by
# `lab.sh kind-load`; and waiting for each rollout. Ids, times, counts and
# dates differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@obs:~/shop$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
quiet() { lab as "$*" >/dev/null 2>&1 || true; }
put() { lab as "cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset mesh
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1500"
sleep 60

block front
on "sed -n '/^  listeners:/,/^      filter_chains:/p' envoy/envoy.yaml"
on "curl -s -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d '{\"sku\": \"kettle\", \"qty\": 1, \"card\": \"4111 1111 1111 1111\"}'"
on "docker logs shop-envoy-1 2>&1 | grep '\"listener\":\"storefront\"' | tail -1 | jq -c ."
quiet "for i in \$(seq 1 20); do curl -s -o /dev/null -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d '{\"sku\": \"kettle\", \"qty\": 1, \"card\": \"4111 1111 1111 1111\"}'; done"
sleep 8
on "curl -s localhost:9901/stats | grep -E '^http\.storefront\.downstream_rq_(total|2xx|4xx|5xx):'"
on "curl -s localhost:9901/stats/prometheus | grep -E '^envoy_cluster_upstream_rq_time_bucket\{envoy_cluster_name=\"storefront\",le=\"(25|50|100)\"\}'"

block retries
put compose.override.yaml <<'YAML'
services:
  orders:
    environment:
      PAYMENTS_URL: http://envoy:10001
YAML
on "cat compose.override.yaml"
quiet "docker compose up -d orders"
on "sed -n '/cluster: payments$/,/num_retries/p' envoy/envoy.yaml"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 600"
quiet "echo '{\"fail_every\": 10}' > faults/payments.json"
sleep 90
on "./promq 'sum by (job, code) (rate(http_server_requests_total{job=~\"storefront|payments\",route=~\"/checkout|/charge\"}[1m]))'"
on "curl -s localhost:9901/stats | grep -E '^cluster\.payments\.upstream_rq_(total|retry|retry_success|5xx|503):'"
on "docker logs shop-envoy-1 2>&1 | grep '\"listener\":\"payments\"' | grep -m1 '\"attempts\":2' | jq -c ."

block timeout
quiet "echo '{\"latency_ms\": 2500}' > faults/payments.json"
sleep 30
on "docker logs shop-envoy-1 2>&1 | grep '\"listener\":\"payments\"' | tail -1 | jq -c ."
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{\"sku\": \"kettle\", \"qty\": 1, \"card\": \"4111 1111 1111 1111\"}' -w ' %{http_code}\\n'"
quiet "rm faults/payments.json compose.override.yaml && docker compose up -d orders"

block cost
on "docker stats --no-stream --format '{{.Name}}  {{.CPUPerc}}  {{.MemUsage}}' shop-envoy-1 shop-storefront-1 shop-orders-1"

lab kind-up >/dev/null 2>&1
lab kind-load docker.io/istio/pilot:1.30.5 docker.io/istio/proxyv2:1.30.5 >/dev/null 2>&1
quiet "mkdir -p k8s"
put k8s/mesh.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: server}
spec:
  replicas: 1
  selector: {matchLabels: {app: server}}
  template:
    metadata: {labels: {app: server}}
    spec:
      containers:
        - name: server
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -m, http.server, "8000"]
---
apiVersion: v1
kind: Service
metadata: {name: server}
spec:
  selector: {app: server}
  ports: [{name: http, port: 80, targetPort: 8000}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: client}
spec:
  replicas: 1
  selector: {matchLabels: {app: client}}
  template:
    metadata: {labels: {app: client}}
    spec:
      containers:
        - name: client
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -c, "import time, urllib.request\nwhile True:\n    try: urllib.request.urlopen('http://server/', timeout=2).read()\n    except Exception as e: print(e, flush=True)\n    time.sleep(0.5)"]
YAML
quiet "kubectl wait --for=condition=Ready node --all --timeout=180s"

block istio
on "istioctl install --set profile=minimal --set hub=docker.io/istio -y >/dev/null 2>&1 && kubectl -n istio-system get deployments"
on "kubectl create namespace shop-mesh && kubectl label namespace shop-mesh istio-injection=enabled"
on "kubectl -n shop-mesh apply -f k8s/mesh.yaml"
quiet "kubectl -n shop-mesh rollout status deploy/server deploy/client --timeout=180s"
on "kubectl -n shop-mesh get pods"
on "kubectl -n shop-mesh get pod -l app=server -o jsonpath='{.items[0].spec.containers[*].name}{\"\\n\"}{.items[0].spec.initContainers[*].name}{\"\\n\"}'"
sleep 20

block telemetry
on "kubectl -n shop-mesh exec deploy/server -c istio-proxy -- pilot-agent request GET stats/prometheus 2>/dev/null | grep '^istio_requests_total' | tr ',' '\\n' | grep -E 'source_workload=|destination_workload=|source_principal|response_code|connection_security_policy|^istio_requests_total|} '"

block mtls
on "kubectl create namespace outside && kubectl -n outside run probe --image=shop:1.4.0 --image-pull-policy=Never --restart=Never --command -- sleep 600"
quiet "kubectl -n outside wait --for=condition=Ready pod/probe --timeout=120s"
on "kubectl -n outside exec probe -- python -c \"import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)\""
put k8s/strict.yaml <<'YAML'
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: {name: default, namespace: shop-mesh}
spec:
  mtls: {mode: STRICT}
YAML
on "cat k8s/strict.yaml"
on "kubectl apply -f k8s/strict.yaml"
sleep 10
on "kubectl -n outside exec probe -- python -c \"import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)\" 2>&1 | tail -2"
on "kubectl -n shop-mesh logs deploy/client -c client --since=20s | wc -l"

block linkerd
on "linkerd version --client"
on "linkerd install --crds --set installGatewayAPI=true 2>/dev/null | grep '^kind:' | sort | uniq -c"
on "linkerd install --ignore-cluster | grep -E '^kind:|image:' | sort | uniq -c"

quiet "kubectl delete namespace shop-mesh outside"
lab kind-down
