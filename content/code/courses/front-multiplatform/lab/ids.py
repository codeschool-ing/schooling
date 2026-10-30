#!/usr/bin/env python3
"""ids.py PREFIX N: N fresh ids, checked against everything under content/, docs/,
and this lab's id pool (lab/ids.used), which records every id handed out."""
import pathlib, secrets, sys
A = "0123456789abcdefghjkmnpqrstvwxyz"
root = pathlib.Path("/home/user/schooling")
used = pathlib.Path(__file__).with_name("ids.used")
corpus = []
for d in ("content", "docs", "tools", "internal"):
    for p in (root / d).rglob("*"):
        if p.is_file() and p.suffix in (".json", ".md", ".go", ".py", ".sh", ".sql", ".mjs", ".js"):
            try: corpus.append(p.read_text(errors="ignore"))
            except Exception: pass
blob = "\n".join(corpus) + (used.read_text() if used.exists() else "")
prefix, n = sys.argv[1], int(sys.argv[2])
out = []
while len(out) < n:
    i = prefix + "-" + "".join(secrets.choice(A) for _ in range(8))
    if i not in blob and i not in out:
        out.append(i)
with used.open("a") as f: f.write("\n".join(out) + "\n")
print("\n".join(out))
