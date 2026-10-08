#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of rag, as a script that produces
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
# processors and no graphics card, through OpenAI's SDK at temperature 0 or
# through Anthropic's SDK, whose messages.create at this version takes no
# temperature; every vector is all-minilm (1b226e2802db). The Anthropic runs
# go to Ollama's own implementation of the Messages API, not to Anthropic.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-jdk1t7y1
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py rag.py last_query.py documents.py rag_claude.py stream.py fragile.py budget.py
lab exec 'python ingest.py' >/dev/null

block whole
on 'python rag.py "How long after my return arrives will I get the refund?"'
on 'python rag.py "Can I place an order by phone?"'
block log
on 'wc -l < queries.jsonl'
on 'python rag.py "How long is a gift card valid?" > /dev/null; python last_query.py'
block documents
on 'python documents.py "How long is a gift card valid?"'
on 'python documents.py "How long is a gift card valid?" plain'
block claude
on 'python rag_claude.py "How long is a gift card valid?"'
block stream
on 'python stream.py "How long is a gift card valid?"'
block fragile
on 'OPENAI_LOG=info python fragile.py "How long is a gift card valid?" 2>&1'
block budget
on 'python budget.py "How long after my return arrives will I get the refund?" 400'
on 'python budget.py "How long after my return arrives will I get the refund?" 250'
