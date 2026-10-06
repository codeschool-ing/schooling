#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), and copying the course's programs into ~/obs: telemetry.py,
# redact.py, assistant.py and tree.py from ../../lab/code, which the lesson
# shows in the parts it discusses, and one_call.py and auto.py, which it
# shows in full.
#
# EVERY REPLY IN THIS LESSON CAME FROM extract-1, the lab's stand-in model,
# which copies sentences out of its sources by rules written in rag's
# lab/labgen.py, and EVERY TIMING from labobs, which waits by rules written at
# the top of ../../lab/labobs.py. Neither is a language model or a provider.
# Span ids, trace ids and timings change on every run; the lesson quotes one
# run, and its prose quotes only what the run printed.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, on 2026-10-06.
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
use telemetry.py redact.py assistant.py tree.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl'

put one_call.py <<'PY'
"""One model call, with a span around it, printed to the terminal when it ends."""
from openai import OpenAI
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("one_call")

client = OpenAI()
with tracer.start_as_current_span("chat extract-1") as span:
    span.set_attribute("gen_ai.operation.name", "chat")
    span.set_attribute("gen_ai.request.model", "extract-1")
    reply = client.chat.completions.create(
        model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    span.set_attribute("gen_ai.response.model", reply.model)
    span.set_attribute("gen_ai.response.finish_reasons", [reply.choices[0].finish_reason])
    span.set_attribute("gen_ai.usage.input_tokens", reply.usage.prompt_tokens)
    span.set_attribute("gen_ai.usage.output_tokens", reply.usage.completion_tokens)
print(reply.choices[0].message.content)
PY

put auto.py <<'PY'
"""The same call with no span written by hand: OpenInference instruments the SDK."""
from openai import OpenAI
from openinference.instrumentation.openai import OpenAIInstrumentor

import telemetry

provider = telemetry.setup("auto.jsonl")
OpenAIInstrumentor().instrument(tracer_provider=provider)

client = OpenAI()
reply = client.chat.completions.create(
    model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
print(reply.choices[0].message.content)
PY

block the-lab
on 'ls'
on 'wc -l data/traffic.jsonl data/eval.jsonl'
on 'curl -s http://127.0.0.1:8600/; echo'
on 'cat releases.json'
on 'python assistant.py "How long is a gift card valid?"'

block one-call
on 'python one_call.py'

block the-chain
on 'python assistant.py "Above what order value is standard delivery free?"'
on 'python tree.py'

block attributes
on 'python tree.py --attrs'

block refused
on 'python assistant.py "Is there a student discount?"'
on 'python tree.py'
on 'python tree.py --attrs | sed -n "/search/,/check_citations/p"'

block auto
on 'python auto.py'
on 'python tree.py --spans auto.jsonl --attrs'
on 'rm auto.jsonl; OPENINFERENCE_ENABLE_GENAI_SEMCONV=true python auto.py'
on 'python tree.py --spans auto.jsonl --attrs | grep gen_ai'

block trace-ids
on 'wc -l spans.jsonl'
on 'python -c "import json; print(sorted({json.loads(l)[\"trace\"] for l in open(\"spans.jsonl\")}))"'
T=$(lab exec 'head -1 spans.jsonl' | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["trace"][:8])')
on "grep -c $T spans.jsonl"
on "python tree.py $T"
