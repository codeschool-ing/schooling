"""facts.py: a run graded against the facts of the evaluation set, two ways."""
import json
import re
import sys

REFUSAL = "I could not find that in our documents."
cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def exact(reply, facts):
    return reply == REFUSAL if not facts else any(f in reply for f in facts)


def normalised(reply, facts):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    return reply == REFUSAL if not facts else any(squash(f) in squash(reply) for f in facts)


if __name__ == "__main__":
    run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
    for name, grade in (("exact", exact), ("normalised", normalised)):
        right = [r["id"] for r in run if grade(r["reply"], cases[r["id"]]["facts"])]
        print(f"{name:10} {len(right)}/{len(run)} right")
    wrong = [r for r in run if not normalised(r["reply"], cases[r["id"]]["facts"])]
    for r in wrong:
        print(f"  {r['id']}  {r['question'][:52]:52}  {r['reply'][:60]}")
