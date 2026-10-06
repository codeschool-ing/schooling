#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), starting Langfuse and the recorder (lab.sh langfuse, lab.sh
# recorder, as root), copying the course's programs into ~/obs from
# ../../lab/code, and waiting twenty seconds after each replay for Langfuse's
# worker to file what arrived. The programs this lesson writes are put below
# and shown in full.
#
# LANGFUSE IS REAL: version 3.225.11, self-hosted from the images pinned in
# ../../lab/langfuse/docker-compose.yml, with the lab's keys. LANGSMITH WAS NOT
# RUN: it is a hosted service whose self-hosted edition is for enterprise
# customers. Its Python SDK is real and was run, against ../../lab/recorder.py,
# which keeps what the SDK sends and is not LangSmith. Replies come from
# extract-1, the lab's stand-in model; the week and its customers are
# simulated, as lessons 3 and 5 say. The extract-1 prices sent to Langfuse are
# the course's, from prices.json.
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
lab langfuse >/dev/null
lab recorder >/dev/null
rm -f /var/lib/recorder/requests.jsonl
use telemetry.py redact.py assistant.py replay.py tree.py costs.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl'

put lf.py <<'PY'
"""lf.py: a few questions to Langfuse's public API, one line per answer."""
import base64
import json
import os
import sys
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
AUTH = {"Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()}


def get(path):
    request = urllib.request.Request(os.environ["LANGFUSE_HOST"] + path, headers=AUTH)
    return json.load(urllib.request.urlopen(request))


what = sys.argv[1]
if what == "traces":   # traces DAY N: the first N traces of DAY, a local date
    day = f"fromTimestamp={sys.argv[2]}T03:00:00Z&toTimestamp={sys.argv[2]}T23:59:59Z"
    for t in get(f"/api/public/traces?{day}&limit={sys.argv[3]}&orderBy=timestamp.asc")["data"]:
        print(t["timestamp"][:19], t["id"][:8], t["name"], "user", t["userId"], "session", t["sessionId"],
              "cost", t["totalCost"], "input", repr(t["input"]))
elif what == "observations":   # observations TRACE: every observation of one trace, by its full id
    trace = sys.argv[2]
    for o in sorted(get(f"/api/public/observations?traceId={trace}")["data"], key=lambda o: o["startTime"]):
        print(f"{o['type']:10} {o['name']:16} model {o['model']}  usage {o['usageDetails']}  cost {o['calculatedTotalCost']}")
elif what == "daily":
    for d in get("/api/public/metrics/daily")["data"]:
        print(d["date"], f"{d['countTraces']:4} traces", "cost", round(d["totalCost"], 6))
elif what == "scores":
    values = [s["value"] for s in get(f"/api/public/v2/scores?name={sys.argv[2]}&limit=100")["data"]]
    print(f"{len(values)} scores named {sys.argv[2]}: {values.count(1)} of value 1, {values.count(0)} of value 0")
PY

put lf_names.py <<'PY'
"""lf_names.py: a span processor that adds, as each span starts, the names Langfuse reads."""
from opentelemetry.sdk.trace import SpanProcessor


class LangfuseNames(SpanProcessor):
    def on_start(self, span, parent_context=None):
        if span.name == "ask":
            a = span.attributes
            span.set_attribute("langfuse.observation.type", "span")   # the root is not a model call
            span.set_attribute("user.id", a["user.hash"])               # the pseudonym, under the name it reads
            span.set_attribute("langfuse.trace.input", a["app.question"])
PY

put lf_prices.py <<'PY'
"""lf_prices.py: extract-1's two prices from prices.json, as model definitions in Langfuse."""
import base64
import json
import os
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
for i, p in enumerate(json.load(open("prices.json"))["models"]["extract-1"]):
    name = "extract-1" if i == 0 else f"extract-1 from {p['from']}"   # a model's name is unique in a project
    body = {"modelName": name, "matchPattern": "(?i)^extract-1$", "startDate": p["from"] + "T00:00:00-03:00",
            "unit": "TOKENS", "inputPrice": float(p["input"]) / 1e6, "outputPrice": float(p["output"]) / 1e6}
    request = urllib.request.Request(os.environ["LANGFUSE_HOST"] + "/api/public/models", data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json",
                                              "Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()})
    m = json.load(urllib.request.urlopen(request))
    print("model", m["modelName"], "from", m["startDate"], "input", m["inputPrice"], "output", m["outputPrice"])
PY

put lf_scores.py <<'PY'
"""lf_scores.py: every thumb in feedback.jsonl, sent to Langfuse as a score on the trace it is about."""
import json

from langfuse import get_client

langfuse = get_client()
sent = 0
for f in map(json.loads, open("feedback.jsonl")):
    if f["kind"] == "thumbs":
        langfuse.create_score(trace_id=f["trace"], name="thumbs", value=1 if f["value"] == "up" else 0,
                              data_type="BOOLEAN")
        sent += 1
langfuse.flush()
print(sent, "scores sent")
PY

put ls_ask.py <<'PY'
"""ls_ask.py: one question, traced with the LangSmith SDK, which sends its runs to LANGSMITH_ENDPOINT."""
import sys

from langsmith import Client, traceable
from langsmith.wrappers import wrap_openai
from openai import OpenAI

import redact

if "--redact" in sys.argv:   # LangSmith's own hooks, applied before anything is sent
    client = Client(hide_inputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    hide_outputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    omit_traced_runtime_info=True)
else:
    client = Client()
openai = wrap_openai(OpenAI())


@traceable(name="ask", client=client)
def ask(question):
    reply = openai.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": question}])
    return reply.choices[0].message.content


print(ask("Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"))
client.flush()
PY

put sent.py <<'PY'
"""sent.py: what the recorder received, one line per run, with what each carried."""
import json

for request in map(json.loads, open("/var/lib/recorder/requests.jsonl")):
    for part in request["body"]:
        op, run, *field = part["name"].split(".")
        body = part["body"]
        if not field:
            print(f"{op:5} run {run[:8]} {body['name']} ({body['run_type']})")
        elif body:
            print(f"        {field[0]}: {json.dumps(body, ensure_ascii=False)[:110]}")
PY

LS='LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=lab-langsmith-key-0001 LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true'
OTEL='OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_HOST/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"'

block health
on 'curl -s $LANGFUSE_HOST/api/public/health; echo'

block send
on "export $OTEL; python replay.py --from 2026-10-04 --to 2026-10-05"
sleep 20
on 'python lf.py traces 2026-10-04 1'
T=$(lab exec 'python -c "import costs; print(next(r[\"trace\"] for r in costs.requests() if r[\"output\"]))"')
on "python lf.py observations $T"

block names
on "export $OTEL; python replay.py --from 2026-10-03 --to 2026-10-04 --processor lf_names:LangfuseNames"
sleep 20
on 'python lf.py traces 2026-10-03 1'

block prices
on 'python lf_prices.py'
on "export $OTEL; rm spans.jsonl; python replay.py --from 2026-10-02 --to 2026-10-03 --processor lf_names:LangfuseNames"
sleep 20
on 'python lf.py daily'
on 'python -c "import costs; print(sum(r[\"cost\"] for r in costs.requests()))"'

block scores
on 'python lf_scores.py'
sleep 10
on 'python lf.py scores thumbs'

block langsmith
on "$LS python ls_ask.py"
sleep 2
on 'python sent.py'
rm -f /var/lib/recorder/requests.jsonl
on "$LS python ls_ask.py --redact"
sleep 2
on 'python sent.py'
