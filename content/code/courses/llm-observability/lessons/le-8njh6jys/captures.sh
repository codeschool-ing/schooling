#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), starting Helicone and Phoenix (lab.sh helicone, lab.sh
# phoenix, as root), copying the course's programs into ~/obs from
# ../../lab/code, and a five-second wait after the replay for Phoenix to
# receive the last batch. The programs this lesson writes are put below and
# shown in full.
#
# HELICONE IS REAL, self-hosted from its all-in-one image at the digest pinned
# in ../../lab.sh. Its gateway refuses to forward to the lab's provider, which
# is the lesson's point; nothing was sent through it to any real provider,
# because no key for one existed. ARIZE PHOENIX IS REAL, version 20.18.0, run
# from its Python package. Arize AX, the hosted product, was not run. Replies
# come from extract-1, the lab's stand-in model.
#
# Recorded on Ubuntu 24.04, Python 3.11, Docker 29.8, TZ=America/Sao_Paulo, on
# 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/obs$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/llmobs-capture.lock; flock 9
lab reset >/dev/null
lab langfuse-down >/dev/null
lab helicone >/dev/null
lab phoenix >/dev/null
use telemetry.py redact.py assistant.py replay.py tree.py costs.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl'

put via_gateway.py <<'PY'
"""via_gateway.py: one call through Helicone's gateway, asking it to forward to the lab's provider."""
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:8585/v1/gateway/oai/v1", default_headers={
    "Helicone-Target-Url": "http://127.0.0.1:8600",   # where the gateway should forward the request
    "Helicone-User-Id": "d89d2eeb16257c0f",           # what Helicone files the request under
    "Helicone-Property-Feature": "help",
})
try:
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
except Exception as e:
    print(f"{type(e).__name__}: {e}")
PY

put px_spans.py <<'PY'
"""px_spans.py: the spans Phoenix holds, read back through its client, as a table per span name."""
from phoenix.client import Client

spans = Client(base_url="http://127.0.0.1:6006").spans.get_spans_dataframe(project_identifier="default", limit=5000)
print(len(spans), "spans;", spans["context.trace_id"].nunique(), "traces")
print(spans["span_kind"].value_counts().to_string())
spans["ms"] = (spans["end_time"] - spans["start_time"]).dt.total_seconds() * 1000
table = spans.groupby("name").agg(spans=("name", "size"), kind=("span_kind", "first"), median_ms=("ms", "median"),
                                  prompt_tokens=("attributes.llm.token_count.prompt", "sum"))
print(table.round(0).to_string())
PY

put px_thumbs.py <<'PY'
"""px_thumbs.py: each thumb in feedback.jsonl, as an annotation on its trace's root span in Phoenix."""
import json

import pandas as pd
from phoenix.client import Client

root = {s["trace"]: s["span"] for s in map(json.loads, open("spans.jsonl")) if s["parent"] is None}
thumbs = [f for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"]
rows = pd.DataFrame({"span_id": [root[f["trace"]] for f in thumbs], "label": [f["value"] for f in thumbs],
                     "score": [1 if f["value"] == "up" else 0 for f in thumbs]})
client = Client(base_url="http://127.0.0.1:6006")
client.spans.log_span_annotations_dataframe(dataframe=rows, annotation_name="thumbs", annotator_kind="HUMAN", sync=True)
got = client.spans.get_span_annotations_dataframe(span_ids=rows["span_id"], project_identifier="default")
print(len(rows), "sent;", len(got), "read back:", got["result.label"].value_counts().to_dict())
PY

block helicone
on 'curl -s http://127.0.0.1:8585/healthcheck; echo'
on 'python via_gateway.py'

block phoenix
on 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:6006/'
on 'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:6006/v1/traces python replay.py --from 2026-10-04 --to 2026-10-05'
sleep 5
on 'python px_spans.py'

block annotations
on 'python px_thumbs.py'
