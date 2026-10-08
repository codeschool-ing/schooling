#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every vector is
# all-minilm (Ollama tag 1b226e2802db); every mark the reranker gives is
# llama3.2:3b (a80c4f17acd5) at temperature 0, served by Ollama 0.40.0 on four
# processors and no graphics card.
#
# The reset leaves ~/rag as lesson 5 began it, so the edits lesson 5 makes are
# made here first, as a student's machine would carry them, and then undone
# by the commands the first section shows.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-5kge9jmv
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py show.py measure.py reorder.py scores.py
lab exec 'python ingest.py && sed -i "s/We refund within three working days/We refund within two working days/" data/docs/returns-policy.md && sed -i "s/^status: current$/status: superseded/" data/docs/gift-cards.md && rm data/docs/returns-policy-2025.md && python ingest.py' >/dev/null
python3 "$COURSE/lab/shown.py" "$COURSE" docs.sh > /home/ana/rag/docs.sh

block restore
on 'sh docs.sh'
on 'psql -qc "DROP TABLE chunks"'
on 'python ingest.py'
block first
on 'python show.py vector "How much is express delivery?"'
block lexical-vector
on 'python show.py vector "What does error E-4104 mean?"'
on 'python show.py lexical "What does error E-4104 mean?"'
block lexical-lexical
on 'python show.py lexical "how do I send a book back"'
block hybrid-show
on 'python show.py hybrid "What does error E-4104 mean?"'
block rerank-express
on 'python reorder.py "How much is express delivery?" "9.90"'
block rerank-window
on 'python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"'
block rewrite-short
on 'python show.py vector "And for e-books?"'
block rewrite-long
on 'python show.py vector "How long do I have to return an e-book?"'
block filter-none
on 'python show.py vector "Who pays for the return postage?"'
block filter-on
on 'python -c "from search import vector; [print(r[1]) for r in vector(\"Who pays for the return postage?\", 3, \"status = %s AND audience = %s\", (\"current\", \"public\"))]"'
block threshold
on 'python scores.py | sort -r'
block measure
on 'python measure.py'
