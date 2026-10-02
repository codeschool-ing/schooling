#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset elastic`; checkout.json (lesson 1); the
# redaction filter, the override files and the Collector configuration, whose
# contents the lesson shows; simulated customers, five requests a second, for
# ten minutes before the cost block; and the copies of storefront/app.py and
# the Collector's file taken before each edit and put back after. The card is
# the standard test number and the token is made up: neither works anywhere.
# Sizes, ids, times and dates differ on every run.
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
lokiq() { echo "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query=$1' --data-urlencode since=5m"; }

lab reset elastic
put checkout.json <<'JSON'
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
JSON
put compose.override.yaml <<'YAML'
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
YAML
sed -i 's/, otlp_grpc\/graylog\]/]/' /home/ana/shop/otel/collector-logs.yaml
quiet "docker compose up -d otel-collector"
sleep 5
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 600"
sleep 620

block cost
on "docker compose logs --no-log-prefix --since 10m storefront orders payments mailer | wc -c"
on "curl -s 'localhost:9200/_cat/indices/logs-*?h=docs.count,store.size'"
on "grep -A3 limits_config loki/loki.yaml"

block retention
on "curl -s -X PUT localhost:9200/_ilm/policy/shop-logs -H 'Content-Type: application/json' -d '{\"policy\": {\"phases\": {\"hot\": {\"actions\": {\"rollover\": {\"max_age\": \"1d\"}}}, \"delete\": {\"min_age\": \"7d\", \"actions\": {\"delete\": {}}}}}}'; echo"
on "curl -s localhost:9200/_ilm/policy/shop-logs | jq -c '.\"shop-logs\".policy.phases | map_values(.min_age)'"

block leak
quiet "cp services/storefront/app.py /tmp/storefront.app.py"
on "sed -i 's/^        body = request.get_json()$/&\n        log.debug(\"request\", extra={\"fields\": {\"headers\": dict(request.headers), \"body\": body}})/' services/storefront/app.py && grep -n 'log.debug' services/storefront/app.py"
put compose.override.yaml <<'YAML'
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
  storefront:
    environment:
      LOG_LEVEL: DEBUG
YAML
on "docker compose up -d storefront 2>&1 | tail -1"
sleep 6
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json"
sleep 8
on "$(lokiq '{service_name="storefront"} |= "Bearer"') | jq -r '.data.result[].values[][1]' | jq -c '{message, card: .body.card, auth: .headers.Authorization}'"

block redact-source
put services/common/redact.py <<'PY'
"""A logging filter that keeps secrets and card numbers out of every line."""
import logging
import re

CARD = re.compile(r"\b(?:\d[ -]?){12,15}(\d{4})\b")
SECRET_KEYS = {"authorization", "cookie", "password", "token", "card"}


def clean(value):
    if isinstance(value, dict):
        return {k: "[removed]" if k.lower() in SECRET_KEYS else clean(v) for k, v in value.items()}
    if isinstance(value, str):
        return CARD.sub(r"**** \1", value)
    return value


class Redact(logging.Filter):
    def filter(self, record):
        record.fields = clean(getattr(record, "fields", {}))
        record.msg = clean(str(record.msg))
        return True
PY
quiet "cp services/common/logs.py /tmp/logs.py"
on "sed -i 's/^    handler.setFormatter(JsonFormatter())$/&\n    handler.addFilter(redact.Redact())/; s/^from opentelemetry import trace$/&\n\nfrom common import redact/' services/common/logs.py && grep -n 'redact' services/common/logs.py"
on "docker compose restart storefront 2>&1 | tail -1"
sleep 6
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d '{\"sku\": \"kettle\", \"qty\": 1, \"card\": \"4111 1111 1111 1111\", \"note\": \"paid with 5500 0000 0000 0004\"}'"
sleep 8
on "$(lokiq '{service_name="storefront"} | json | message="request"') --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{auth: .headers.Authorization, body}'"
quiet "cp /tmp/logs.py services/common/logs.py"

block redact-pipeline
python3 - <<'PY'
p = "/home/ana/shop/otel/collector-logs.yaml"
s = open(p).read()
s = s.replace("""        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")""", """        statements:
          - replace_pattern(body, "\\\\b(?:\\\\d[ -]?){12,15}(\\\\d{4})\\\\b", "**** $$1")
          - replace_pattern(body, "Bearer [A-Za-z0-9._-]+", "Bearer [removed]")
          - merge_maps(attributes, ParseJSON(body), "upsert")""")
open("/home/ana/shop/otel/collector-redact.yaml", "w").write(s)
PY
chown ana:ana /home/ana/shop/otel/collector-redact.yaml
on "diff otel/collector-logs.yaml otel/collector-redact.yaml"
on "sed -i 's#collector-logs.yaml#collector-redact.yaml#' compose.override.yaml && docker compose up -d otel-collector 2>&1 | tail -1"
on "docker compose restart storefront 2>&1 | tail -1"
sleep 6
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json"
sleep 8
on "$(lokiq '{service_name="storefront"} | json | message="request"') --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{card: .body.card, auth: .headers.Authorization}'"
on "docker compose logs --no-log-prefix storefront | grep '\"request\"' | tail -1 | jq -c '{card: .body.card, auth: .headers.Authorization}'"

block erase
on "curl -s -o /dev/null -w '%{http_code}\n' -X POST -G localhost:3100/loki/api/v1/delete --data-urlencode 'query={service_name=\"storefront\"} |= \"sk_live_9f8e7d6c5b4a\"' --data-urlencode start=\$(date -d '-1 hour' +%s)"
on "curl -s localhost:3100/loki/api/v1/delete | jq -c '.[] | {query, status}'"
on "curl -s -X POST localhost:9200/logs-generic.otel-default/_delete_by_query -H 'Content-Type: application/json' -d '{\"query\": {\"match_phrase\": {\"body.text\": \"sk_live_9f8e7d6c5b4a\"}}}' | jq -c '{deleted, failures}'"

quiet "cp /tmp/storefront.app.py services/storefront/app.py; rm compose.override.yaml otel/collector-redact.yaml"
