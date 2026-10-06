"""evalrun.py: every question of an evaluation set through the assistant, kept as a run.

    python evalrun.py NAME [--set data/eval.jsonl] [--at 2026-10-05T12:00:00] [--release R]

A run is runs/NAME.jsonl: one line per question with its id, the question, the
reply, the release that answered, the sources the model was shown (their ids
and their text) and the trace id. Later lessons grade runs and compare them;
they never call the assistant themselves, so a run can be graded again, by
another method, without asking the model twice.
"""
import argparse
import json
import os

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("name")
p.add_argument("--set", default="data/eval.jsonl")
p.add_argument("--at", default="2026-10-05T12:00:00", help="the moment whose release answers")
p.add_argument("--release", help="answer with this release, whatever the moment")
a = p.parse_args()

if a.release:   # a release not yet in force: answer as if it were
    assistant.RELEASES = {a.release: dict(assistant.RELEASES[a.release], **{"from": "0000"})}
telemetry.setup("eval-spans.jsonl", service="evalrun")
os.makedirs("runs", exist_ok=True)
text = dict(assistant.db.execute("SELECT id, text FROM chunks").fetchall())
n = 0
with open(f"runs/{a.name}.jsonl", "w") as out:
    for case in map(json.loads, open(a.set)):
        reply, sources, trace = assistant.ask(case["question"], user="evalrun", feature="help", at=a.at)
        release, _ = assistant.release_at(a.at)
        out.write(json.dumps({"id": case["id"], "question": case["question"], "reply": reply, "release": release,
                              "sources": [{"id": s[0], "text": text[s[0]]} for s in sources],
                              "trace": trace}, ensure_ascii=False) + "\n")
        n += 1
print(f"runs/{a.name}.jsonl: {n} questions, release {release}")
