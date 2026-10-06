#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), copying the course's programs into ~/obs from
# ../../lab/code, and the two runs of the evaluation set, which lesson 10
# shows. The programs this lesson writes are put below and shown in full.
#
# DeepEval 4.2.8 and RAGAS 0.3.1 run here for real, with their telemetry
# turned off by /etc/llmobs.env (DEEPEVAL_TELEMETRY_OPT_OUT, RAGAS_DO_NOT_TRACK).
# NO LANGUAGE MODEL WAS REACHABLE, so neither framework's model-graded metrics
# were run: the one attempt shown is refused by judge-1, the lab's stand-in
# judge, and the request log it reads is labobs's own. The metrics that ran
# are DeepEval metrics written in this lesson around judge-1 and lesson 8's
# fact check, and RAGAS's metrics that need no model. Every score called
# judge-1's is judge-1's, which grades by embedding similarity by rules written
# at the top of ../../lab/labobs.py; it is not a language model.
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
use telemetry.py redact.py assistant.py checks.py evalrun.py judge.py facts.py
lab exec 'python evalrun.py old --release 2026.09.4 >/dev/null && python evalrun.py new --release 2026.10.1 >/dev/null'

put builtin.py <<'PY'
"""builtin.py: one of DeepEval's own metrics, answer relevancy, pointed at the lab's judge."""
from deepeval.metrics import AnswerRelevancyMetric
from deepeval.models import OpenAIModel
from deepeval.test_case import LLMTestCase

metric = AnswerRelevancyMetric(model=OpenAIModel(model="judge-1"), async_mode=False)
case = LLMTestCase(input="How much is express delivery?",
                   actual_output="Express delivery is not free at any order value. [1]")
try:
    metric.measure(case)
except Exception as e:
    print(type(e).__name__, e)
PY

put last_request.py <<'PY'
"""last_request.py: the last request the lab's model server received, as its log recorded it."""
import json

last = json.loads(open("/var/log/labgen/requests.jsonl").read().splitlines()[-1])
body = last["request"]
print("model ", body["model"], "  status", last["status"])
for m in body["messages"]:
    text = m["content"] if isinstance(m["content"], str) else m["content"][0]["text"]
    print(f"{m['role']}:\n{text}")
PY

put deepeval_run.py <<'PY'
"""deepeval_run.py: the sixty replies of lesson 10 as DeepEval test cases, graded by two metrics written here."""
import json
from collections import defaultdict

from deepeval import evaluate
from deepeval.evaluate.configs import AsyncConfig, DisplayConfig
from deepeval.metrics import BaseMetric
from deepeval.test_case import LLMTestCase

import checks
import judge
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


class JudgeRelevance(BaseMetric):
    """judge-1's relevance verdict, the agreed refusal passed by rule as lesson 10 decided."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        if checks.is_refusal(case.actual_output):
            self.score, self.reason = 1.0, "the agreed refusal, passed by rule"
        else:
            v = judge.grade("relevance", case.input, case.actual_output,
                            [{"id": "", "text": t} for t in case.retrieval_context])
            self.score, self.reason = float(v["verdict"] == "pass"), v["reason"]
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "judge-1 relevance"


class FactCheck(BaseMetric):
    """Lesson 8's normalised fact check: the expected fact is in the reply, or an unanswerable question was refused."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        facts = case.metadata["facts"]
        self.score = float(normalised(case.actual_output, facts))
        self.reason = "fact found" if self.score else "fact missing"
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "fact check"


tests = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        tests.append(LLMTestCase(name=f"{r['id']} {r['release']}", input=r["question"], actual_output=r["reply"],
                                 retrieval_context=[s["text"] for s in r["sources"]],
                                 metadata={"facts": cases[r["id"]]["facts"], "release": r["release"]}))
result = evaluate(tests, [JudgeRelevance(), FactCheck()], async_config=AsyncConfig(run_async=False),
                  display_config=DisplayConfig(print_results=False, show_indicator=False))
passed = defaultdict(int)
for t in result.test_results:
    for m in t.metrics_data:
        passed[t.metadata["release"], m.name] += m.success
for release in ("2026.09.4", "2026.10.1"):
    print(release, "  ".join(f"{name} {passed[release, name]}/30" for name in ("judge-1 relevance", "fact check")))
PY

put ragas_run.py <<'PY'
"""ragas_run.py: RAGAS's context precision and recall that need no model, beside lesson 11's own, per release.

The reference contexts are the text of every chunk in the question's gold sections."""
import json
from statistics import mean

import psycopg
from ragas import EvaluationDataset, SingleTurnSample, evaluate
from ragas.metrics import NonLLMContextPrecisionWithReference, NonLLMContextRecall

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
by_section, section = {}, {}
for cid, doc, path, text in psycopg.connect().execute("SELECT id, doc_id, path, text FROM chunks ORDER BY doc_id, position"):
    section[cid] = (doc, path.split(" > ")[-1])
    by_section.setdefault(section[cid], []).append(text)


def ours(chunks, gold):
    """Lesson 11's two definitions: precision weighted by rank over chunks in a gold section,
    recall as the share of gold sections at least one chunk came from."""
    hits = [section[c] in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return (sum(at) / len(at) if at else 0.0), sum(g in {section[c] for c in chunks} for g in gold) / len(gold)


for run in ("old", "new"):
    rows = [json.loads(line) for line in open(f"runs/{run}.jsonl")]
    samples, own = [], []
    for r in rows:
        gold = [tuple(g) for g in cases[r["id"]]["gold"]]
        if not gold or not r["sources"]:
            continue   # RAGAS needs both lists non-empty; lesson 11 left these out too
        samples.append(SingleTurnSample(user_input=r["question"], response=r["reply"],
                                        retrieved_contexts=[s["text"] for s in r["sources"]],
                                        reference_contexts=[t for g in gold for t in by_section[g]]))
        own.append(ours([s["id"] for s in r["sources"]], gold))
    scores = evaluate(EvaluationDataset(samples=samples), show_progress=False,
                      metrics=[NonLLMContextPrecisionWithReference(), NonLLMContextRecall()]).to_pandas()
    print(f"{run} {rows[0]['release']}, {len(samples)} questions with gold and chunks")
    print(f"  RAGAS      precision {scores['non_llm_context_precision_with_reference'].mean():.2f}"
          f"   recall {scores['non_llm_context_recall'].mean():.2f}")
    print(f"  lesson 11  precision {mean(p for p, _ in own):.2f}   recall {mean(r for _, r in own):.2f}")
PY

block builtin
on 'python builtin.py'
on 'python last_request.py'

block deepeval
on 'python deepeval_run.py | grep -E "Pass Rate|^2026"'
on 'ls -a .deepeval'

block ragas
on 'python ragas_run.py'
