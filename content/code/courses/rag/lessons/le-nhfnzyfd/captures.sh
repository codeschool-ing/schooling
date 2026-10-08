#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every reply and
# every verdict of the judge is llama3.2:3b (Ollama tag a80c4f17acd5) at
# temperature 0, served by Ollama 0.40.0 on four processors and no graphics
# card; every vector is all-minilm (1b226e2802db).
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-nhfnzyfd
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py verify.py evaluate.py why.py judge.py
lab exec 'python ingest.py' >/dev/null

block testset
on 'head -n 3 data/eval.jsonl'
on 'tail -n 2 data/eval.jsonl'
block testset-split
on 'python -c "import json; qs = [json.loads(l) for l in open(\"data/eval.jsonl\")]; print(\" \".join(q[\"id\"] for q in qs if int(q[\"id\"][1:]) % 3 == 0))"'
block dev
on 'python evaluate.py --split dev'
block dev-list
on 'python evaluate.py --split dev --list'
block wrong
on 'python why.py "Who pays for the return postage?"'
on 'python why.py "My e-book was downloaded yesterday, can I still get my money back?"'
on 'python why.py "What is the most a support agent can refund without approval?"'
block judge
on 'python judge.py'
block compare-floor
on 'python evaluate.py --split dev --floor 0.44'
on 'python evaluate.py --split dev --floor 0.44 --list | grep e14'
on 'python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"'
block compare-k
on 'python evaluate.py --split dev --k 1'
block ci-pass
on 'python evaluate.py --split held-out --min-correct 0.7; echo "exit $?"'
block ci-fail
on 'python evaluate.py --split held-out --min-correct 0.7 --floor 0.7; echo "exit $?"'
