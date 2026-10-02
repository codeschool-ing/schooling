#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5;
# compose.override.yaml and the two files in k8s/, whose contents the lesson
# shows; simulated customers, five requests a second, started in the
# background; waiting for Docker to call orders healthy or unhealthy; the kind
# cluster, created by `lab.sh kind-up` with the shop's image loaded into it;
# and waiting for each deployment to roll out. Pod names, ids, times and dates
# differ on every run.
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
until_status() { for _ in $(seq 1 60); do lab as "docker compose ps orders" | grep -q "($1)" && return; sleep 2; done; }

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1500"
sleep 60

block lies
on "docker compose stop postgres 2>&1 | tail -1"
sleep 5
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{\"sku\": \"kettle\", \"qty\": 1, \"card\": \"4111 1111 1111 1111\"}' -w ' %{http_code}\\n'"
on "curl -s localhost:8080/health"
sleep 45
on "./promq 'probe_success'"
on "./promq 'sum(rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\",code=~\"5..\"}[1m])) / sum(rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[1m]))'"
quiet "docker compose start postgres"
sleep 30

block docker
put compose.override.yaml <<'YAML'
services:
  orders:
    healthcheck:
      test: ["CMD", "python", "-c", "import http.client as h; c = h.HTTPConnection('localhost', 8081, timeout=3); c.request('GET', '/ready'); r = c.getresponse(); print(r.status, r.read().decode()); exit(r.status != 200)"]
      interval: 5s
      timeout: 4s
      retries: 3
      start_period: 10s
YAML
on "cat compose.override.yaml"
quiet "docker compose up -d orders"
until_status healthy
on "docker compose ps orders --format '{{.Name}}  {{.Status}}'"
on "docker compose stop postgres 2>&1 | tail -1"
until_status unhealthy
on "docker compose ps orders --format '{{.Name}}  {{.Status}}'"
on "docker inspect --format '{{json .State.Health}}' shop-orders-1 | jq -r '.Status, .FailingStreak, (.Log[-1].Output | sub(\"\\\\s+$\"; \"\"))'"
on "docker inspect --format '{{.RestartCount}}' shop-orders-1"

block synthetic
on "sed -n '/^  checkout:/,\$p' blackbox.yml"
on "docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '"
quiet "docker compose start postgres"
until_status healthy
on "docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '"
on "docker compose ps orders --format '{{.Name}}  {{.Status}}'"

lab kind-up
quiet "mkdir -p k8s"
put k8s/probe-demo.yaml <<'YAML'
# Two copies of a small web server whose probes a test can break on purpose:
# /ready fails while /tmp/unready exists, /live while /tmp/stuck does.
apiVersion: v1
kind: ConfigMap
metadata: {name: web}
data:
  web.py: |
    import os
    from http.server import BaseHTTPRequestHandler, HTTPServer

    FAILS_IF = {"/live": "/tmp/stuck", "/ready": "/tmp/unready"}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            marker = FAILS_IF.get(self.path)
            ok = not (marker and os.path.exists(marker))
            self.send_response(200 if ok else 503)
            self.end_headers()
            self.wfile.write(os.environ["HOSTNAME"].encode() + b"\n")

        def log_message(self, *args):
            pass

    HTTPServer(("", 8000), Handler).serve_forever()
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: web}
spec:
  replicas: 2
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      containers:
        - name: web
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, /web/web.py]
          volumeMounts: [{name: code, mountPath: /web}]
          readinessProbe:
            httpGet: {path: /ready, port: 8000}
            periodSeconds: 2
            failureThreshold: 2
          livenessProbe:
            httpGet: {path: /live, port: 8000}
            periodSeconds: 3
            failureThreshold: 3
      volumes: [{name: code, configMap: {name: web}}]
---
apiVersion: v1
kind: Service
metadata: {name: web}
spec:
  selector: {app: web}
  ports: [{port: 80, targetPort: 8000}]
YAML
put k8s/deep.yaml <<'YAML'
# A stand-in database, and a service whose LIVENESS probe checks that it can
# reach it: the mistake this part of the lesson is about.
apiVersion: apps/v1
kind: Deployment
metadata: {name: db}
spec:
  replicas: 1
  selector: {matchLabels: {app: db}}
  template:
    metadata: {labels: {app: db}}
    spec:
      containers:
        - name: db
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -m, http.server, "5432"]
---
apiVersion: v1
kind: Service
metadata: {name: db}
spec:
  selector: {app: db}
  ports: [{port: 5432}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: deep}
spec:
  replicas: 3
  selector: {matchLabels: {app: deep}}
  template:
    metadata: {labels: {app: deep}}
    spec:
      containers:
        - name: deep
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -m, http.server, "8000"]
          livenessProbe:
            exec:
              command: [python, -c, "import socket; socket.create_connection(('db', 5432), 1)"]
            periodSeconds: 3
            failureThreshold: 3
YAML
quiet "kubectl wait --for=condition=Ready node --all --timeout=180s"

block kube
on "kubectl apply -f k8s/probe-demo.yaml"
quiet "kubectl rollout status deployment web --timeout=180s"
on "kubectl get pods"

block readiness
P=$(lab as "kubectl get pods -l app=web -o name" | head -1 | cut -d/ -f2)
Q=$(lab as "kubectl get pods -l app=web -o name" | tail -1 | cut -d/ -f2)
on "kubectl exec $P -- touch /tmp/unready"
sleep 8
on "kubectl get pods"
on "kubectl get endpointslice -l kubernetes.io/service-name=web -o json | jq -r '.items[].endpoints[] | [.targetRef.name, .conditions.ready] | @tsv'"
on "kubectl exec $P -- rm /tmp/unready"

block liveness
on "kubectl exec $Q -- touch /tmp/stuck"
sleep 40
on "kubectl get pods"
on "kubectl get events --field-selector involvedObject.name=$Q --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep -E 'REASON|Liveness|Killing'"

block kills
on "kubectl apply -f k8s/deep.yaml"
quiet "kubectl rollout status deployment deep --timeout=180s"
on "kubectl get pods -l app=deep"
on "kubectl scale deployment db --replicas=0"
sleep 150
on "kubectl get pods -l app=deep"
on "kubectl scale deployment db --replicas=1"
sleep 60
on "kubectl get pods -l app=deep"
quiet "kubectl delete -f k8s/deep.yaml -f k8s/probe-demo.yaml"
lab kind-down
quiet "rm compose.override.yaml && docker compose up -d orders"
