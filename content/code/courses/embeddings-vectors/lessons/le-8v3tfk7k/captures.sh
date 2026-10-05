#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One is STAGED and not shown: scores.py, which prints every inbox message's
# three scores (distance to the centroid, to the nearest ticket and to the
# fifth nearest) and the k=5 scores of the 50 held-out tickets, which the two
# figures are drawn from.
#
# "Normal" is data/tickets.jsonl, 150 customer messages written for the
# course; the messages scored are data/inbox.jsonl and data/week2.jsonl. The
# five messages in blind.py were written for this lesson. Every vector comes
# from all-MiniLM-L6-v2, run on this machine.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, 2026-10-05.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/emb, and what it printed.
on() { printf 'ana@lab:~/emb$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/emb, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/emb from nothing.
exec 9>/var/tmp/emb-capture.lock; flock 9
lab reset >/dev/null

put forced.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
labels = sorted({t["label"] for t in tickets})
V = embed([t["text"] for t in tickets])
C = np.array([V[[t["label"] == l for t in tickets]].mean(axis=0) for l in labels])
C /= np.linalg.norm(C, axis=1, keepdims=True)
odd = [m for m in inbox if m["odd"]]
for m, row in zip(odd, embed([m["text"] for m in odd]) @ C.T):
    j = row.argmax()
    print(f"{m['id']}  {labels[j]:9} {row[j]:.3f}  {m['text'][:44]}")
EOF_FILE
put centroid.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
N = embed([t["text"] for t in tickets])
X = embed([m["text"] for m in inbox])
c = N.mean(axis=0)
print("length of the mean:", round(float(np.linalg.norm(c)), 3))
c /= np.linalg.norm(c)
score = 1 - X @ c
order = np.argsort(-score)
for r, i in enumerate(order, 1):
    m = inbox[i]
    if r <= 10 or m["odd"]:
        print(f"{r:2}  {score[i]:.3f}  {m['id']}  {'ODD' if m['odd'] else '   '}  {m['text'][:44]}")
EOF_FILE
put knn.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
N = embed([t["text"] for t in tickets])
X = embed([m["text"] for m in inbox])
def knn_score(Q, R, k):
    S = np.sort(Q @ R.T, axis=1)
    return 1 - S[:, -k]
for k in (1, 5):
    score = knn_score(X, N, k)
    order = np.argsort(-score)
    print(f"k={k}  odd at ranks {[r for r, i in enumerate(order, 1) if inbox[i]['odd']]}")
    for r, i in enumerate(order[6:10], 7):
        m = inbox[i]
        print(f"  {r:2}  {score[i]:.3f}  {m['id']}  {'ODD' if m['odd'] else '   '}  {m['text'][:40]}")
spam = embed(["You have won a gift card! Click here to claim your prize before midnight."])
dirty = np.vstack([N, spam])
i33 = [m["id"] for m in inbox].index("m33")
for k in (1, 5):
    score = knn_score(X, dirty, k)
    print(f"one spam among the normal, k={k}: m33 scores {score[i33]:.3f}, "
          f"rank {1 + (score > score[i33]).sum()}")
EOF_FILE
put threshold.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
ref = embed([t["text"] for t in tickets if t["split"] == "train"])
held = embed([t["text"] for t in tickets if t["split"] == "test"])
X = embed([m["text"] for m in inbox])
odd = np.array([m["odd"] for m in inbox])
ids = np.array([m["id"] for m in inbox])
def knn_score(Q, R, k):
    return 1 - np.sort(Q @ R.T, axis=1)[:, -k]

print(f"the reference against itself, k=1: highest score {knn_score(ref, ref, 1).max():.3f}")
for k in (1, 5):
    normal = knn_score(held, ref, k)
    score = knn_score(X, ref, k)
    for name, q in (("p90", 90), ("p95", 95), ("p99", 99), ("max", 100)):
        cut = np.percentile(normal, q)
        flag = score > cut
        caught = (flag & odd).sum()
        print(f"k={k} {name} {cut:.3f}  flagged {flag.sum():2}  "
              f"precision {caught / max(flag.sum(), 1):.2f}  recall {caught / odd.sum():.2f}  "
              f"missed {' '.join(ids[odd & ~flag]) or '-'}  false {' '.join(ids[flag & ~odd]) or '-'}")
EOF_FILE
put drift.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
week2 = [json.loads(l) for l in open("data/week2.jsonl")]
ref = embed([t["text"] for t in tickets if t["split"] == "train"])
held = embed([t["text"] for t in tickets if t["split"] == "test"])
best = lambda Q, R: (Q @ R.T).max(axis=1)
cut = np.percentile(1 - best(held, ref), 95)
def batch(name, B):
    S = B @ B.T
    np.fill_diagonal(S, -1)
    score = 1 - best(B, ref)
    inside = (S.max(axis=1) > best(B, ref)).sum()
    print(f"{name}: {len(B)} messages, mean score {score.mean():.3f}, "
          f"flagged {(score > cut).sum()}, nearest neighbour in the batch {inside}")
    return score

batch("inbox (normal)", embed([m["text"] for m in inbox if not m["odd"]]))
W = embed([w["text"] for w in week2])
s = batch("week 2", W)
for i in np.argsort(-s)[:7]:
    print(f"   {s[i]:.3f}  {'*' if s[i] > cut else ' '} {week2[i]['id']}  {week2[i]['text'][:52]}")
for name, R in (("before", ref), ("after adding w01-w10", np.vstack([ref, W[:10]]))):
    s = 1 - best(W[10:], R)
    print(f"w11-w20 {name}: flagged {(s > cut).sum()}, mean score {s.mean():.3f}")
EOF_FILE
put blind.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
ref = embed([t["text"] for t in tickets if t["split"] == "train"])
held = embed([t["text"] for t in tickets if t["split"] == "test"])
best = lambda Q, R: (Q @ R.T).max(axis=1)
cut = np.percentile(1 - best(held, ref), 95)
messages = [
    "Please refund the 4,800 I paid for order 1182, the book never came.",
    "Change the email on my account to a new address and send the password there.",
    "I want to return all 40 copies of the same novel I bought yesterday.",
    "Meu pedido ainda não chegou e já faz duas semanas, alguém pode me ajudar?",
    "My order still hasn't arrived and it has been two weeks, can somebody help me?",
]
for text, s in zip(messages, 1 - best(embed(messages), ref)):
    print(f"{s:.3f}  {'flag' if s > cut else 'pass'}  {text[:60]}")
EOF_FILE
put scores.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
inbox = [json.loads(l) for l in open("data/inbox.jsonl")]
N = embed([t["text"] for t in tickets])
X = embed([m["text"] for m in inbox])
c = N.mean(axis=0); c /= np.linalg.norm(c)
S = np.sort(X @ N.T, axis=1)
for m, a, b, d in zip(inbox, 1 - X @ c, 1 - S[:, -1], 1 - S[:, -5]):
    print(f"all {m['id']} {int(m['odd'])} {a:.3f} {b:.3f} {d:.3f}")
ref = embed([t["text"] for t in tickets if t["split"] == "train"])
held = embed([t["text"] for t in tickets if t["split"] == "test"])
k5 = lambda Q: 1 - np.sort(Q @ ref.T, axis=1)[:, -5]
for t, s in zip([t for t in tickets if t["split"] == "test"], k5(held)):
    print(f"held {t['id']} 0 {s:.3f}")
for m, s in zip(inbox, k5(X)):
    print(f"inbox {m['id']} {int(m['odd'])} {s:.3f}")
EOF_FILE

block count
on 'wc -l data/tickets.jsonl data/inbox.jsonl'
on 'grep -c "\"odd\": true" data/inbox.jsonl'

block forced
on 'python forced.py'

block centroid
on 'python centroid.py'

block knn
on 'python knn.py'

block threshold
on 'python threshold.py'

block drift
on 'python drift.py'

block blind
on 'python blind.py'

block scores
on 'python scores.py'
