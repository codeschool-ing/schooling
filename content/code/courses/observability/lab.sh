#!/usr/bin/env bash
# The machine every transcript in the observability course was recorded on.
#
# IT IS ONE LINUX COMPUTER RUNNING DOCKER. The shop the course instruments is
# five small Python services and a nightly job, written for this course and
# printed in full below; everything that watches it is real, unmodified
# open-source software, each in the official image named beside it:
#
#   the shop (written for the course, image shop:1.4.0 built from python:3.12-slim)
#     storefront   where a checkout arrives; instrumented by hand (lesson 2)
#     orders       stores the order; no telemetry code, run under
#                  opentelemetry-instrument (lesson 3)
#     payments     approves or declines a charge; can be told to be slow or
#                  to fail through faults/payments.json
#     mailer       takes paid orders off a RabbitMQ queue (lesson 4)
#     report       the nightly job, run by hand with `docker compose run`
#     loadgen      simulated customers: a fixed mix of 20 requests, repeated
#     sandbox      the same image, for running the small scripts in ~/shop/scratch
#     pager        Alertmanager's webhook lands here and becomes a log line
#   what it runs on
#     postgres 16.15, rabbitmq 4.2
#   what watches it
#     OpenTelemetry Collector contrib 0.161.0, Prometheus 3.15.0,
#     Alertmanager 0.34.1, Pushgateway 1.11.3, node_exporter 1.12.1,
#     postgres_exporter 0.20.1,
#     blackbox_exporter 0.28.0, Grafana 13.0.10, Loki 3.7.8, Jaeger 2.21.0,
#     Zipkin 3.6.1
#   and, only in the lessons that need them (compose profiles)
#     elastic      Elasticsearch 9.5.3 (lesson 9)
#     graylog      Graylog 7.0.13, MongoDB 8.0, OpenSearch 2.19.6 (lesson 9)
#     mesh         Envoy 1.39.2 (lesson 19)
#   and a Kubernetes cluster for lessons 14 and 19: kind 0.33.0, node v1.37.0
#
# Elasticsearch and OpenSearch run with their disk watermarks switched off:
# they measure the host's whole disk, and on the machine this was recorded on
# that disk is shared, so its free space said nothing about the lab's. On a
# machine of your own, leave them on.
#
# Every port is published on 127.0.0.1 only. Nothing here reaches the internet
# once the images and the Python wheels are downloaded.
#
#   sudo bash lab.sh up           write ~/shop, build the image, start it all
#   sudo bash lab.sh reset        stop it, delete every volume, start again
#   sudo bash lab.sh down
#   sudo bash lab.sh as 'cmd'     run a command as ana, in ~/shop
#   sudo bash lab.sh up PROFILE   also start a profile: elastic, graylog, mesh
#   sudo bash lab.sh kind-up | kind-down
#   sudo bash lab.sh kind-load IMAGE...   pull an image here, copy it into kind
#
# Recorded on Ubuntu 24.04 with Docker Engine 29.6 and Compose 5.3,
# TZ=America/Sao_Paulo. The machine needs 4 CPUs and 8 GB of memory, and
# 16 GB while the graylog profile runs.
set -euo pipefail

USER_LAB=ana
SHOP=/home/$USER_LAB/shop
export TZ=America/Sao_Paulo

as_ana() { su - "$USER_LAB" -c "cd $SHOP && $*"; }

# Every file of ~/shop is a fence in a lesson, under a paragraph that opens with
# its path, `~/shop/<path>`; the student copies it from there, and this reads it
# from there. There is no second copy to drift.
FILES_FROM=(
  le-7fgac3dc/the-shop.md
  le-7fgac3dc/what-watches-it.md
)

extract() {
  python3 - "$SHOP" "$@" <<'PY'
import os, re, sys
shop, sources = sys.argv[1], sys.argv[2:]
fence = re.compile(r"^`~/shop/([^`]+)`[^\n]*\n(?:[^\n]+\n)*\n```[a-z]*\n(.*?)^```$", re.M | re.S)
seen = {}
for src in sources:
    for m in fence.finditer(open(src).read()):
        path, body = m.group(1), m.group(2)
        if path in seen:
            sys.exit(f"lab: ~/shop/{path} is written in {seen[path]} and again in {src}")
        seen[path] = src
        out = os.path.join(shop, path)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, "w").write(body)
print(len(seen))
PY
}

write_files() {
  local here n
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  mkdir -p "$SHOP/faults" "$SHOP/scratch" "$SHOP/grafana/dashboards"
  touch "$SHOP/services/common/__init__.py" 2>/dev/null || { mkdir -p "$SHOP/services/common"; touch "$SHOP/services/common/__init__.py"; }
  n=$(extract "${FILES_FROM[@]/#/$here/lessons/}")
  [ "$n" -ge 22 ] || { echo "lab: only $n files found in the lessons" >&2; exit 1; }
  mkdir -p "$SHOP/envoy"
  cat > "$SHOP/envoy/envoy.yaml" <<'LABFILE'
# Envoy for lesson 19: one proxy, two listeners, playing the part a mesh's
# sidecars play. :10000 sits in front of the storefront; :10001 sits between
# orders and payments, with a timeout and retries. :9901 is Envoy's admin page.
static_resources:
  listeners:
    - name: storefront
      address: {socket_address: {address: 0.0.0.0, port_value: 10000}}
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: storefront
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                      log_format:
                        json_format:
                          listener: storefront
                          method: "%REQ(:METHOD)%"
                          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                          code: "%RESPONSE_CODE%"
                          ms: "%DURATION%"
                          upstream_ms: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
                          attempts: "%UPSTREAM_REQUEST_ATTEMPT_COUNT%"
                          flags: "%RESPONSE_FLAGS%"
                route_config:
                  virtual_hosts:
                    - name: storefront
                      domains: ["*"]
                      routes:
                        - match: {prefix: /}
                          route: {cluster: storefront, timeout: 5s}
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
    - name: payments
      address: {socket_address: {address: 0.0.0.0, port_value: 10001}}
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: payments
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                      log_format:
                        json_format:
                          listener: payments
                          method: "%REQ(:METHOD)%"
                          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                          code: "%RESPONSE_CODE%"
                          ms: "%DURATION%"
                          attempts: "%UPSTREAM_REQUEST_ATTEMPT_COUNT%"
                          flags: "%RESPONSE_FLAGS%"
                route_config:
                  virtual_hosts:
                    - name: payments
                      domains: ["*"]
                      routes:
                        - match: {prefix: /}
                          route:
                            cluster: payments
                            timeout: 2s
                            retry_policy:
                              retry_on: 5xx
                              num_retries: 2
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
  clusters:
    - name: storefront
      type: STRICT_DNS
      load_assignment:
        cluster_name: storefront
        endpoints: [{lb_endpoints: [{endpoint: {address: {socket_address: {address: storefront, port_value: 8080}}}}]}]
    - name: payments
      type: STRICT_DNS
      load_assignment:
        cluster_name: payments
        endpoints: [{lb_endpoints: [{endpoint: {address: {socket_address: {address: payments, port_value: 8082}}}}]}]
admin:
  address: {socket_address: {address: 0.0.0.0, port_value: 9901}}
LABFILE
  mkdir -p "$SHOP/otel"
  cat > "$SHOP/otel/collector-fanout.yaml" <<'LABFILE'
# The Collector of collector.yaml, sending every trace to one more place
# (lesson 13): an OTLP endpoint of the kind a hosted product gives you, with the
# key that identifies the account read from the environment.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp
  otlp_http/vendor:
    endpoint: http://vendor:4318
    encoding: json
    headers:
      api-key: ${env:VENDOR_API_KEY}

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp_grpc/jaeger, zipkin, otlp_http/vendor]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
LABFILE
  mkdir -p "$SHOP/otel"
  cat > "$SHOP/otel/collector-logs.yaml" <<'LABFILE'
# The same Collector, sending every log line to three stores at once:
# Loki, Elasticsearch and Graylog. Lesson 9 switches to it.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp
  elasticsearch:
    endpoints: [http://elasticsearch:9200]
  otlp_grpc/graylog:
    endpoint: graylog:4317
    tls:
      insecure: true

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki, elasticsearch, otlp_grpc/graylog]
LABFILE
  mkdir -p "$SHOP/otel"
  cat > "$SHOP/otel/collector-sampling.yaml" <<'LABFILE'
# The Collector of collector.yaml, deciding which traces to keep (lesson 12).
# Every span still feeds the span metrics; only the traces worth reading go
# on to Jaeger and Zipkin.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

connectors:
  # Rate, errors and duration per service and span name, computed from every
  # span before any of them is dropped.
  spanmetrics:
    metrics_flush_interval: 15s
    histogram:
      explicit:
        buckets: [10ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s]

processors:
  # Wait until a trace has had time to finish, then keep it if any policy says so.
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp
  otlp_http/prometheus:
    endpoint: http://prometheus:9090/api/v1/otlp

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces/all:
      receivers: [otlp]
      processors: [memory_limiter]
      exporters: [spanmetrics]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    metrics/spans:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [otlp_http/prometheus]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
LABFILE
}

put_shown() {
  # A file a capture writes into ~/shop is one the student was shown: its
  # whole text is in a lesson, as a fence, as the output of a `cat`, or as the
  # parts of an annotated example put together. Anything else is refused, so a
  # capture cannot run a program the lessons never gave.
  local here; here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  local tmp; tmp=$(mktemp)
  cat > "$tmp"
  python3 - "$here/lessons" "$1" "$tmp" <<'PY' || { rm -f "$tmp"; exit 1; }
import glob, json, re, sys
lessons, path, tmp = sys.argv[1:]
body = open(tmp).read().rstrip("\n")
texts = []
for md in glob.glob(f"{lessons}/*/*.md"):
    if md.endswith(".pt.md"):
        continue
    t = open(md).read()
    texts.append(t)
    for ex in re.findall(r"^```schooling-example\n(.*?)^```$", t, re.M | re.S):
        texts.append("".join(p["code"] for p in json.loads(ex)["parts"]))
if not any(body in t for t in texts):
    sys.exit(f"lab: {path} is not shown whole in any lesson")
PY
  as_ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'" < "$tmp"
  rm -f "$tmp"
}

base_image() {
  # THE ONE THING THIS MACHINE NEEDS THAT A STUDENT'S DOES NOT. The computer the
  # course is recorded on reaches the internet only through a proxy that
  # re-signs TLS, so pip inside a build trusts nothing it is shown. This puts
  # the proxy's certificate into python:3.12-slim under its own name, so the
  # student's Dockerfile builds unchanged: the same base, the same packages
  # from the same index, at the same pinned versions.
  [ -n "${HTTPS_PROXY:-}" ] && [ -f /root/.ccr/ca-bundle.crt ] || return 0
  docker image inspect python:3.12-slim --format '{{index .Config.Labels "lab.proxy-ca"}}' 2>/dev/null | grep -q yes && return 0
  local d; d=$(mktemp -d)
  cp /root/.ccr/ca-bundle.crt "$d/ca.crt"
  printf 'FROM python:3.12-slim\nCOPY ca.crt /etc/ssl/proxy-ca.crt\nENV PIP_CERT=/etc/ssl/proxy-ca.crt\nLABEL lab.proxy-ca=yes\n' > "$d/Dockerfile"
  { docker image inspect python:3.12-slim >/dev/null 2>&1 || docker pull -q python:3.12-slim >/dev/null; } && docker build -q -t python:3.12-slim "$d" >/dev/null
  rm -rf "$d"
}

build() {
  base_image
  docker build -q --network host ${HTTPS_PROXY:+--build-arg HTTPS_PROXY=$HTTPS_PROXY} -t shop:1.4.0 "$SHOP" >/dev/null
}

wait_for() {
  local what=$1 url=$2 i
  for i in $(seq 1 90); do
    curl -fs -o /dev/null "$url" && return 0
    sleep 2
  done
  echo "lab: $what did not come up at $url" >&2
  return 1
}

up() {
  id "$USER_LAB" >/dev/null 2>&1 || useradd -m -s /bin/bash -G docker "$USER_LAB"
  write_files
  [ -f "$SHOP/.grafana-password" ] || openssl rand -hex 12 > "$SHOP/.grafana-password"
  build
  if [ ! -f "$SHOP/.graylog.env" ]; then
    openssl rand -hex 12 > "$SHOP/.graylog-password"
    printf 'GRAYLOG_PASSWORD_SECRET=%s\nGRAYLOG_ROOT_PASSWORD_SHA2=%s\n' "$(openssl rand -hex 32)" \
      "$(tr -d '\n' < "$SHOP/.graylog-password" | sha256sum | cut -d' ' -f1)" > "$SHOP/.graylog.env"
  fi
  chown -R "$USER_LAB:$USER_LAB" "$SHOP"
  local profiles=""
  for p in "$@"; do profiles+=" --profile $p"; done
  as_ana "docker compose$profiles up -d --quiet-pull" >/dev/null 2>&1
  wait_for storefront http://127.0.0.1:8080/health
  wait_for prometheus http://127.0.0.1:9090/-/ready
  wait_for loki http://127.0.0.1:3100/ready
  wait_for jaeger http://127.0.0.1:16686/
  wait_for grafana http://127.0.0.1:3000/api/health
  wait_for zipkin http://127.0.0.1:9411/health
  case " $* " in *" elastic "*) wait_for elasticsearch http://127.0.0.1:9200/ ;; esac
  case " $* " in *" graylog "*) wait_for graylog http://127.0.0.1:9000/api/ ;; esac
  # the mailer connects when rabbitmq is ready, which is a few seconds later
  for i in $(seq 1 60); do
    as_ana "docker compose logs mailer" 2>/dev/null | grep -q 'waiting for orders' && break
    sleep 2
  done
}

down() { [ -d "$SHOP" ] && as_ana "docker compose --profile '*' down -v --remove-orphans" >/dev/null 2>&1 || true; }

kind_up() {
  # Two settings that only a nested machine needs, like the one this was
  # recorded on: its cgroups are v1, and a container inside it may not lower
  # its own OOM score. A cluster on an ordinary Linux machine needs neither.
  cat > /tmp/kind-lab.yaml <<'KIND'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
  - |-
    [plugins."io.containerd.cri.v1.runtime"]
      restrict_oom_score_adj = true
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: KubeletConfiguration
        failCgroupV1: false
KIND
  kind get clusters 2>/dev/null | grep -qx lab || kind create cluster --name lab --config /tmp/kind-lab.yaml >/dev/null 2>&1
  mkdir -p /home/$USER_LAB/.kube
  kind get kubeconfig --name lab > /home/$USER_LAB/.kube/config
  chown -R "$USER_LAB:$USER_LAB" /home/$USER_LAB/.kube
  kind load docker-image shop:1.4.0 --name lab >/dev/null 2>&1
}

kind_load() {
  # An image pulled on this machine, copied into the cluster's node. `kind load`
  # refuses images published for several platforms, and the node itself
  # cannot reach a registry through this machine's proxy.
  docker pull -q "$1" >/dev/null &&
    docker save "$1" | docker exec -i lab-control-plane ctr -n k8s.io images import --snapshotter=overlayfs - >/dev/null
}

case "${1:-}" in
  up) shift; up "$@" ;;
  reset) shift; down; rm -rf "$SHOP"; up "$@" ;;
  down) down ;;
  as) shift; as_ana "$*" ;;
  put) shift; put_shown "$1" ;;
  kind-up) kind_up ;;
  kind-load) shift; for i in "$@"; do kind_load "$i"; done ;;
  kind-down) kind delete cluster --name lab >/dev/null 2>&1 || true ;;
  *) sed -n '2,/^set -e/p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
