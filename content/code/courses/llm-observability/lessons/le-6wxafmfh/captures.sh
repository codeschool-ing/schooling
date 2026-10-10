#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh            # builds the lab from nothing, then records
#
# It starts by removing Ollama, its models and ana, and builds them again with
# the steps lesson 1 shows, so that the setup sections record a real first
# install, and the failures a student meets on the way: the installer without
# zstd, Ollama installed and not running, a second server on the same port,
# pip outside the environment, the environment not active, and the server
# stopped under a program.
#
# THE MODEL'S REPLIES. The assistant and one_call.py ask at temperature 0, so
# on this machine the same question gets the same reply; `ollama run` draws at
# random with Ollama's defaults, and a rerun words it differently.
#
#   model    llama3.2:3b (a80c4f17acd5), llama3.2:1b (baf6a787fdff) and
#            all-minilm (1b226e2802db), pulled from registry.ollama.ai by
#            Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~$ or ana@dev:~/obs$ is what ana typed and
# what it printed. What is STAGED rather than typed, and not shown: the lab's
# own steps (lab.sh), and the files ana wrote (put and stage below), each of
# which a lesson shows whole; put refuses one that no lesson shows byte for
# byte. Span ids, trace ids and timings change on every run; the lesson quotes
# one run, and its prose quotes only what the run printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

quiet lab purge
quiet apt-get remove -y zstd
quiet lab user

block fails-zstd
home 'curl -fsSL https://ollama.com/install.sh -o install-ollama.sh'
home 'sh install-ollama.sh'

quiet lab system
block fails-not-running
home 'ollama --version'
home 'ollama list'

quiet lab serve
block fails-serve-twice
home 'timeout 5 ollama serve'

quiet lab models
block models
home 'ollama --version'
home 'ollama list'
homeq 'ollama run llama3.2:3b "Say hello to a customer in one short sentence."'
home 'ollama ps'

quiet lab small
block your-machine-small
homeq 'ollama run llama3.2:1b "Say hello to a customer in one short sentence."'
home 'ollama ps'
home 'ollama list'
block your-machine-speed
for m in llama3.2:3b llama3.2:1b; do
  home "curl -s http://127.0.0.1:11434/api/generate -d '{\"model\": \"$m\", \"prompt\": \"Explain in two sentences what a gift card is.\", \"stream\": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r[\"eval_count\"], \"tokens in\", round(r[\"eval_duration\"] / 1e9, 1), \"seconds\")'"
done

block fails-pip-outside
bare 'python3 -m pip install openai==3.24.0'

quiet lab venv
block fails-not-active
bare 'python3 -c "import openai"'

block check
home 'python --version'
home 'env | grep ^OPENAI_ | sort'
home "python -c 'from openai import OpenAI; r = OpenAI().chat.completions.create(model=\"llama3.2:3b\", max_tokens=10, messages=[{\"role\": \"user\", \"content\": \"Reply with the word ready.\"}]); print(r.choices[0].finish_reason, r.usage.prompt_tokens, r.usage.completion_tokens, repr(r.choices[0].message.content))'"
block sizes
home 'du -sh ~/llmobs'

python3 "$COURSE/lab/fences.py" named the-project.md make-obs.sh | IN_HOME=1 BARE=1 lab exec 'cat > make-obs.sh'
block make
home 'bash make-obs.sh ~/obs'
on 'ls -R'
stage index.py le-6wxafmfh/the-project.md
stage redact.py le-6wxafmfh/the-project.md
block index
on 'python index.py'

block fails-stopped
quiet lab unserve
on "python -c 'from openai import OpenAI; OpenAI().chat.completions.create(model=\"llama3.2:3b\", messages=[{\"role\": \"user\", \"content\": \"Hello\"}])' 2>&1 | tail -n 1"
quiet lab serve

put one_call.py <<'PY'
"""one_call.py: one model call, with a span around it, printed to the terminal when it ends."""
from openai import OpenAI
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("one_call")

client = OpenAI()
with tracer.start_as_current_span("chat llama3.2:3b") as span:
    span.set_attribute("gen_ai.operation.name", "chat")
    span.set_attribute("gen_ai.request.model", "llama3.2:3b")
    reply = client.chat.completions.create(
        model="llama3.2:3b", temperature=0,
        messages=[{"role": "user", "content": "How long is a Marginalia gift card valid?"}])
    span.set_attribute("gen_ai.response.model", reply.model)
    span.set_attribute("gen_ai.response.finish_reasons", [reply.choices[0].finish_reason])
    span.set_attribute("gen_ai.usage.input_tokens", reply.usage.prompt_tokens)
    span.set_attribute("gen_ai.usage.output_tokens", reply.usage.completion_tokens)
print(reply.choices[0].message.content)
PY
block one-call
on 'python one_call.py'

stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage tree.py le-6wxafmfh/the-chain.md
# The first question after the models load waits for them; the lesson's own
# first trace should show an ordinary call, so the lab asks once and forgets it.
quiet lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl'

block question
on 'python assistant.py "Who pays for the return postage?"'
block tree
on 'python tree.py'
block attrs
on 'python tree.py --attrs'

block discount
on 'python assistant.py "Is there a student discount?"'
on 'python tree.py'
on 'python tree.py --attrs | sed -n "/search/,/check_citations/p"'

block trace-ids
on 'python assistant.py "How long is a gift card valid?"'
on 'wc -l spans.jsonl'
on 'python -c "import json; print(sorted({json.loads(l)[\"trace\"] for l in open(\"spans.jsonl\")}))"'
FIRST=$(lab exec 'head -1 spans.jsonl' | python3 -c 'import json, sys; print(json.load(sys.stdin)["trace"][:8])')
on "grep -c $FIRST spans.jsonl"
on "python tree.py $FIRST"

put auto.py <<'PY'
"""auto.py: the same call with no span written by hand: OpenInference instruments the SDK."""
from openai import OpenAI
from openinference.instrumentation.openai import OpenAIInstrumentor

import telemetry

provider = telemetry.setup("auto.jsonl")
OpenAIInstrumentor().instrument(tracer_provider=provider)

client = OpenAI()
reply = client.chat.completions.create(
    model="llama3.2:3b", temperature=0,
    messages=[{"role": "user", "content": "How long is a Marginalia gift card valid?"}])
print(reply.choices[0].message.content)
PY
block auto
on 'python auto.py'
on 'python tree.py --spans auto.jsonl --attrs'
on 'rm auto.jsonl; OPENINFERENCE_ENABLE_GENAI_SEMCONV=true python auto.py'
on 'python tree.py --spans auto.jsonl --attrs | grep gen_ai'
