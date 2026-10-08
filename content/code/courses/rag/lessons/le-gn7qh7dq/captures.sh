#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of rag, as a script that produces
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
# llama3.2:3b (Ollama tag a80c4f17acd5) at temperature 0, served by Ollama
# 0.40.0 on four processors and no graphics card; every vector is all-minilm
# (1b226e2802db). No fine-tuning is run: the arguments to costs.py are the
# numbers dataset.py and context_tokens.py printed above them in the same run,
# typed as a student would type them after reading them.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-gn7qh7dq
lab reset $L >/dev/null
use vectors.py sections.py dataset.py reindex_cost.py context_tokens.py costs.py

block dataset
out=$(on 'python dataset.py'); printf '%s\n' "$out"
TRAIN=$(printf '%s\n' "$out" | sed -n 's/^training tokens per epoch: //p')
on 'head -n 2 ft.jsonl'
block freshness
on 'python reindex_cost.py'
block trace
on 'python sections.py "How long do I have to return a printed book?"'
on 'grep -n "30 days from delivery" data/docs/returns-policy.md'
block context
out=$(on 'python context_tokens.py'); printf '%s\n' "$out"
CTX=$(printf '%s\n' "$out" | sed -n 's/^retrieved tokens per question, mean: //p')
block costs
on "python costs.py --questions 30000 --context $CTX --train-tokens $TRAIN --epochs 3 --retrains 4 --input-price 3 --train-price 25"
on "python costs.py --questions 30000 --context $CTX --train-tokens ${TRAIN}000 --epochs 3 --retrains 4 --input-price 3 --train-price 25"
block delete
on 'python sections.py "How much does the return label cost?"'
on 'WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"'
