#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# shop_trace.py is extracted from the lesson's own example block. Its ids and
# durations are a real run's, and differ on every run. The Azure Monitor
# exporter is not run: it needs a connection string to a real Application
# Insights resource.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
mkdir -p "$HOME/azure/otel" && cd "$HOME/azure/otel" || exit 1
from_lesson "$HERE/instrumenting.md" shop_trace.py > shop_trace.py

block version
run 'pip list 2>/dev/null | grep opentelemetry'

block run
run 'python3 shop_trace.py'
