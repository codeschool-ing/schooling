#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py, answer.py, verify.py and evaluate.py live
# in ../../lab/code and `use` copies them into ~/rag; ingest.py builds lesson
# 5's index first. Every reply comes from extract-1, the lab's stand-in
# generator, which is not a language model (lab/labgen.py says what it does).
# The judge prompt in the section on model judges was not run: extract-1 cannot
# judge, and no real model was reachable. The questions in data/eval.jsonl and
# the facts that mark a right answer were written for the course.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
use chunking.py ingest.py search.py answer.py verify.py evaluate.py
lab exec 'python ingest.py' >/dev/null

block testset
on 'head -n 3 data/eval.jsonl'
on 'tail -n 2 data/eval.jsonl'
on 'python -c "import json; qs = [json.loads(l) for l in open(\"data/eval.jsonl\")]; print(\" \".join(q[\"id\"] for q in qs if int(q[\"id\"][1:]) % 3 == 0))"'
block dev
on 'python evaluate.py --split dev'
on 'python evaluate.py --split dev --list'
put why.py <<'EOF_FILE'
import sys

from answer import answer

reply, sources = answer(sys.argv[1], where="status = %s", params=("current",))
for n, s in enumerate(sources, 1):
    print(f"[{n}] {s['path']}")
print(reply)
EOF_FILE
block wrong
on 'python why.py "Who pays for the return postage?"'
on 'python why.py "My e-book was downloaded yesterday, can I still get my money back?"'
on 'python why.py "What is the most a support agent can refund without approval?"'
block compare
on 'python evaluate.py --split dev --floor 0.44'
on 'python evaluate.py --split dev --floor 0.44 --list | grep e14'
on 'python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"'
on 'python evaluate.py --split dev --k 1'
block ci
on 'python evaluate.py --split held-out --min-correct 0.7; echo "exit $?"'
on 'python evaluate.py --split held-out --min-correct 0.7 --floor 0.7; echo "exit $?"'
