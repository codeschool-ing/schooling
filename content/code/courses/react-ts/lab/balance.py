"""balance.py LESSON_DIR|exam: where each quiz's key sits by length, and how to spread it.

check-exercises refuses a lesson where the correct option holds one length rank
(longest, second-longest, ...) in more than 45% of its questions, per language.
This prints, for every quiz, the key's rank in each language and, for each
other rank, the length the key would need to take it, so that a rewrite can be
aimed rather than guessed. It changes nothing.
"""
import importlib.util
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
target = sys.argv[1]
name = "exam" if target == "exam" else Path(target).resolve().name
spec = importlib.util.spec_from_file_location("qs", HERE / "exercises" / f"{name}.py")
mod = importlib.util.module_from_spec(spec)
sys.path.insert(0, str(HERE))
spec.loader.exec_module(mod)

tally = {"en": Counter(), "pt": Counter()}
rows = []
for q in mod.QS:
    if q["type"] != "quiz":
        continue
    row = [q["id"]]
    for lang in ("en", "pt"):
        key = [len(c[lang]) for c in q["choices"] if c["ok"]][0]
        others = sorted((len(c[lang]) for c in q["choices"] if not c["ok"]), reverse=True)
        rank = 1 + sum(1 for o in others if o > key)
        if key in others:
            rank = "="
        tally[lang][rank] += 1
        # the range of key lengths for each rank: between neighbours
        bounds = [999] + others + [0]
        ranges = [f"{r + 1}:{bounds[r + 1] + 1}-{bounds[r] - 1}" for r in range(len(others) + 1)]
        row.append(f"{lang} r{rank} len{key} [{' '.join(ranges)}]")
    rows.append(row)
n = len(rows)
for r in rows:
    print("  ".join(r))
for lang in tally:
    worst = max(tally[lang].items(), key=lambda kv: kv[1])
    print(lang, dict(sorted(tally[lang].items(), key=str)), f"max {worst[1]}/{n} = {worst[1] * 100 // max(n, 1)}%")
