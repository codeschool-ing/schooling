#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py, answer.py and verify.py live in
# ../../lab/code and `use` copies them into ~/rag; ingest.py builds lesson 5's
# index first. Every reply comes from extract-1, the lab's stand-in generator,
# which is not a language model (lab/labgen.py says what it does), with ONE
# EXCEPTION: the reply checked in the section on checking citations, in
# made_up.py, was written by the course to imitate two mistakes a real model
# makes, and the section says so. Every similarity was computed on this machine.
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
use chunking.py ingest.py search.py answer.py verify.py
lab exec 'python ingest.py' >/dev/null
put show_prompt.py <<'EOF_FILE'
import sys

from answer import SYSTEM, prompt, sources_for

question = sys.argv[1]
print(SYSTEM)
print("---")
print(prompt(question, sources_for(question)))
EOF_FILE
put made_up.py <<'EOF_FILE'
from answer import sources_for
from verify import check

# A reply WRITTEN BY THE COURSE, not by any model, imitating two mistakes real
# models make: a true sentence cited to the wrong source, and a sentence no
# source says.
reply = ("We refund within three working days of the return reaching our warehouse. [2] "
         "Your bank may take another five to ten days to show it. [1] "
         "Refunds are always paid as store credit. [1]")
sources = sources_for("How long after my return arrives will I get the refund?")
for n, s in enumerate(sources, 1):
    print(f"[{n}] {s['path']}")
for sentence, n, verdict in check(reply, sources):
    print(f"{verdict:20} [{n}] {sentence}")
EOF_FILE
put check_reply.py <<'EOF_FILE'
import sys

from answer import answer
from verify import check

reply, sources = answer(sys.argv[1])
print(reply)
for sentence, n, verdict in check(reply, sources):
    print(f"  {verdict:18} [{n}] {sentence[:60]}")
EOF_FILE
put no_floor.py <<'EOF_FILE'
import sys

from answer import ask

# What the model is sent when the search found nothing above the floor and the
# code calls it anyway: the instructions and the question, and no sources.
print(ask(sys.argv[1], []))
EOF_FILE
put floor.py <<'EOF_FILE'
import glob
import json

from labgen import sentences
from minilm import embed

pool = [s for path in sorted(glob.glob("data/docs/*.md")) for s in sentences(open(path).read())]
vectors = embed(pool)
for line in open("data/eval.jsonl"):
    q = json.loads(line)
    best = float((vectors @ embed(q["question"])[0]).max())
    print(f"{best:.2f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}")
EOF_FILE
put clause.py <<'EOF_FILE'
import re
import sys

from answer import answer
from verify import claims, norm

reply, sources = answer(sys.argv[1])
for sentence, n in claims(reply):
    source = sources[n - 1]
    text = norm(source["text"])
    before = text[:text.find(norm(sentence)[:30])]
    numbers = re.findall(r"(?:^|\s)(\d+\.\d+)\s", before)
    print(f"\"{sentence}\"")
    print(f"  {source['path']}, clause {numbers[-1] if numbers else '?'}, updated {source['updated']}")
EOF_FILE

block prompt
on 'python show_prompt.py "How long after my return arrives will I get the refund?"'
block answer
on 'python answer.py "How long after my return arrives will I get the refund?"'
on 'python answer.py "Can I return a signed copy?"'
on 'python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"'
block verify
on 'python made_up.py'
on 'python check_reply.py "How long after my return arrives will I get the refund?"'
on 'python check_reply.py "Can I return a signed copy?"'
block refuse
on 'python no_floor.py "Can I place an order by phone?"'
on 'python answer.py "Can I place an order by phone?"'
on 'python answer.py "Is there a student discount?"'
on 'python answer.py "Can I pay in instalments?"'
on 'python floor.py | sort -r | sed -n "22,30p"'
block conflict
on 'python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"'
on 'python answer.py "How many days do I have to return a printed book?"'
block legal
on 'python clause.py "When is the contract of sale formed?"'
