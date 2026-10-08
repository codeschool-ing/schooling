#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program and data script comes out of the lessons through lab/shown.py.
# Every reply is llama3.2:3b (Ollama tag a80c4f17acd5) at temperature 0, served
# by Ollama 0.40.0 on four processors and no graphics card; every vector is
# all-minilm (1b226e2802db).
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-km7s5f1e
lab reset $L >/dev/null
use vectors.py sections.py help_search.py
python3 "$COURSE/lab/shown.py" "$COURSE" help.sh $L > /home/ana/rag/help.sh

block e4104
on 'python sections.py "What does error E-4104 mean?"'
on 'grep -n "E-4104" data/docs/*.md'
block ratelimit
on 'python sections.py "What is the rate limit of the affiliate API?"'
block help
on 'sh help.sh'
on 'wc -l data/help.jsonl'
block support-en
on 'python help_search.py "how do I send a book back"'
block support-pt
on 'python help_search.py "como devolvo um livro"'
on 'python help_search.py "quanto custa a entrega expressa"'
block legal
on 'python sections.py "When is the contract of sale formed?"'
on 'grep -n "^2\.2" data/docs/terms-of-sale.md'
block audience
on 'grep -h "^audience:" data/docs/*.md | sort | uniq -c'
block fraud
on 'python sections.py "When does an order get held for manual fraud review?"'
block list14
on 'python sections.py "Which documents mention a 14-day limit?"'
on 'grep -l "14 days" data/docs/*.md'
block summarise
on 'python sections.py "Summarise all of our policies"'
