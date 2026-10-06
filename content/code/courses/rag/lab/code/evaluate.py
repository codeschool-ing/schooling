import argparse
import json
import sys

import answer as pipeline
from search import vector
from verify import check, norm

p = argparse.ArgumentParser(description="Measure retrieval and answers against data/eval.jsonl.")
p.add_argument("--split", choices=["dev", "held-out", "all"], default="dev")
p.add_argument("--floor", type=float, default=pipeline.FLOOR)
p.add_argument("--k", type=int, default=3)
p.add_argument("--list", action="store_true", help="one line per question")
p.add_argument("--min-correct", type=float, default=0.0, help="fail below this share of correct replies")
a = p.parse_args()
pipeline.FLOOR = a.floor


def split_of(q):
    """Every third question is held out, decided by its id and nothing else."""
    return "held-out" if int(q["id"][1:]) % 3 == 0 else "dev"


questions = [q for q in map(json.loads, open("data/eval.jsonl")) if a.split in ("all", split_of(q))]
where, params = "status = %s", ("current",)
ranks, correct, faithful, refused_right, rows = [], 0, 0, 0, []
for q in questions:
    found = vector(q["question"], 5, where, params)
    rank = next((i for i, r in enumerate(found, 1) if any(f in norm(r[2]) for f in q["facts"])), None)
    reply, sources = pipeline.answer(q["question"], k=a.k, where=where, params=params)
    refused = reply == pipeline.REFUSAL
    right = refused if not q["facts"] else not refused and any(f in norm(reply) for f in q["facts"])
    true = refused or all(v.startswith(("quoted", "close")) for _, _, v in check(reply, sources))
    correct += right
    faithful += true
    if q["facts"]:
        ranks.append(rank)
    else:
        refused_right += refused
    rows.append(f"{q['id']}  rank {rank or '-'}  {'refused ' if refused else 'answered'}  "
                f"{'correct' if right else 'WRONG  '}  {'faithful' if true else 'UNFAITHFUL'}  {q['question']}")

n, answerable = len(questions), len(ranks)
hits = lambda k: sum(1 for r in ranks if r and r <= k)
print(f"{a.split}: {n} questions, {answerable} answerable, floor {a.floor}, k {a.k}")
print(f"retrieval  recall@1 {hits(1)}/{answerable}  recall@3 {hits(3)}/{answerable}  recall@5 {hits(5)}/{answerable}"
      f"  MRR {sum(1 / r for r in ranks if r) / answerable:.2f}")
print(f"answers    correct {correct}/{n}  refused rightly {refused_right}/{n - answerable}  faithful {faithful}/{n}")
if a.list:
    print("\n".join(rows))
if correct / n < a.min_correct:
    print(f"FAIL: {correct}/{n} correct is below {a.min_correct:.0%}")
    sys.exit(1)
