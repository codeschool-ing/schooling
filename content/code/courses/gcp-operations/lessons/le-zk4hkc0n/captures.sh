#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of gcp-operations.
#
#   bash lab.sh tools    # once: the OpenTelemetry packages from sdk.md
#   bash captures.sh
#
# The Collector is otel/opentelemetry-collector-contrib:0.137.0, run in a
# container; checkout.py, collector.yaml and collector-gcp.yaml are taken out
# of the lesson. The googlecloud exporter is only validated, never started.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
docker rm -f otel > /dev/null 2>&1
from_lesson "$HERE/sdk.md" checkout.py > checkout.py
from_lesson "$HERE/collector.md" collector.yaml > collector.yaml
from_lesson "$HERE/to-google.md" collector-gcp.yaml > collector-gcp.yaml

block run
run 'docker run -d --rm --name otel -p 4318:4318 -v "$PWD/collector.yaml":/etc/otelcol-contrib/config.yaml otel/opentelemetry-collector-contrib:0.137.0'
sleep 3
run 'python3 checkout.py'
sleep 4
block received
run "docker logs otel 2>&1 | grep -A5 '^ScopeTraces'"
quiet 'docker rm -f otel'

block validate
run 'docker run --rm -v "$PWD/collector-gcp.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml; echo "exit $?"'
run "sed 's/googlecloud:/googlecloud:\\n    projectt: x/' collector-gcp.yaml > bad.yaml"
run 'docker run --rm -v "$PWD/bad.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml 2>&1 | tail -3'
quiet 'rm -f bad.yaml'
