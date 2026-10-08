#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every reply is
# llama3.2:3b (Ollama tag a80c4f17acd5) served by Ollama 0.40.0 on four
# processors and no graphics card, at temperature 0 through OpenAI's SDK;
# every vector is all-minilm (1b226e2802db). The query log is generated with a
# fixed seed by querylog.py, which the lesson shows; nothing in it was measured
# from a real shop.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-gfsavep3
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py querylog.py priced.py split.py repeats.py exact.py semantic.py near.py cached_prompt.py
lab exec 'python ingest.py' >/dev/null

block querylog
on 'python querylog.py'
on 'wc -l data/querylog.jsonl'
on 'head -n 2 data/querylog.jsonl'
block priced
on 'python priced.py'
block split
on 'python split.py'
block repeats
on 'python repeats.py'
block exact
on 'python exact.py'
block semantic
on 'python semantic.py'
block near
on 'python near.py'
block version
on 'python -c "import exact; print(exact.version())"'
on 'sed -i "s/valid for two years from the day it was bought/valid for three years from the day it was bought/" data/docs/gift-cards.md && python ingest.py'
on 'python -c "import exact; print(exact.version())"'
block prompt
on 'python cached_prompt.py'
