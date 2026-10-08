#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of rag, as a script that produces
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
# Every reply and the rewrite are llama3.2:3b (Ollama tag a80c4f17acd5) at
# temperature 0, served by Ollama 0.40.0 on four processors and no graphics
# card; every vector is all-minilm (1b226e2802db). The two conversations are
# the customers' side only, written for the course.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-qd8afg86
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py memory.py chat.py condense.py rewrite.py recalled.py careless.py remembered.py
lab exec 'python ingest.py' >/dev/null
python3 "$COURSE/lab/shown.py" "$COURSE" chats.sh $L > /home/ana/rag/chats.sh

block chats
on 'sh chats.sh'
on 'wc -l data/chat-*.jsonl'
block alone
on 'python chat.py chat-a alone'
block history
on 'python chat.py chat-a history'
block condense
on 'python condense.py'
block rewrite
on 'python rewrite.py chat-a 10 11 12'
block recall
on 'python chat.py chat-a memory > /dev/null'
on 'python recalled.py chat-a A-1001 10 11 12'
block memory
on 'python chat.py chat-a memory'
block state-fn
on 'python -c "import memory; print(memory.state(\"A-1001\", \"Beatriz Costa\"))"'
block state-b
on 'python chat.py chat-b memory'
block careless
on 'python careless.py "Rafael Lima"'
block recalled-b
on 'python recalled.py chat-b A-1002 4'
block forget-list
on 'psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"'
on 'python remembered.py A-1002'
block forget-do
on 'python -c "import memory; print(memory.forget(\"A-1002\"), \"rows deleted\")"'
on 'psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"'
