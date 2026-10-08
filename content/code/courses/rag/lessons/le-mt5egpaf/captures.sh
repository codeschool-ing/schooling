#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program and data script comes out of the lesson's own sections through
# lab/shown.py, so what ran is what the page shows. Every reply is
# llama3.2:3b (Ollama tag a80c4f17acd5) at temperature 0, served by Ollama
# 0.40.0 on four processors and no graphics card; every vector is all-minilm
# (1b226e2802db).
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
lab reset le-mt5egpaf >/dev/null
L=le-mt5egpaf

# The database steps of the setup, from a machine that has none of them yet.
su postgres -c 'psql -qXc "DROP DATABASE IF EXISTS rag"' >/dev/null; su postgres -c 'dropuser --if-exists ana'
block no-role
on 'createdb rag'
su postgres -c 'createuser --superuser ana' 2>/dev/null
on 'createdb rag'
on 'psql -d rag -c "CREATE EXTENSION vector"'

use vectors.py
block checks
on 'ollama list'
on 'ollama run --nowordwrap llama3.2:3b "In one sentence, what are you?"'
on 'python -c "from vectors import embed; v = embed(\"hello\"); print(v.shape, round(float((v ** 2).sum()), 3))"'
on 'psql -c "SELECT extversion FROM pg_extension WHERE extname = '"'"'vector'"'"'"'
lab exec 'ollama run --nowordwrap llama3.2:1b "In one sentence, what are you?"' >/dev/null 2>&1
block memory
on 'ollama ps'

block no-model
on 'python -c "from openai import OpenAI; OpenAI().chat.completions.create(model=\"llama3.2\", messages=[{\"role\": \"user\", \"content\": \"hi\"}])" 2>&1 | tail -1'
block no-venv
bare 'python3 -c "import openai"'
pkill -f 'ollama serve'; sleep 1
block no-server
on 'ollama list'
on 'python -c "from vectors import embed; embed(\"hello\")" 2>&1 | tail -1'
(setsid nohup ollama serve >/var/log/ollama.log 2>&1 </dev/null 9>&- &); sleep 3

python3 "$COURSE/lab/shown.py" "$COURSE" docs.sh $L > /home/ana/rag/docs.sh
python3 "$COURSE/lab/shown.py" "$COURSE" questions.sh $L > /home/ana/rag/questions.sh
block docs
on 'sh docs.sh'
on 'ls data/docs'
on 'wc -w data/docs/*.md | tail -1'
on 'grep -c "14 days" data/docs/*.md | grep -v ":0"'
block front
on 'head -12 data/docs/returns-policy.md'
block questions
on 'sh questions.sh'
on 'wc -l data/*.jsonl'
on 'head -1 data/eval.jsonl'

use ask.py with_doc.py count.py everything.py tiny_rag.py
block closed-book
on 'python ask.py "How many days do I have to return a printed book?"'
on 'python ask.py "What is the phone number for customer service?"'
on 'python ask.py "Can I get my money back for an e-book I downloaded yesterday?"'
block with-doc
on 'python with_doc.py "How many days do I have to return a printed book?"'
on 'python with_doc.py "What is the phone number for customer service?"'
block count
on 'python count.py'
block everything
on 'python everything.py'
block tiny
on 'python tiny_rag.py "How many days do I have to return a printed book?"'
on 'python tiny_rag.py "How much is express delivery?"'
block sections
on 'cat data/docs/*.md | grep -c "^## "'
block postage
on 'python tiny_rag.py "Who pays for the return postage?"'
block phone
on 'python tiny_rag.py "Can I place an order by phone?"'
