#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of rag, as a script that produces
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
# (1b226e2802db); every count of tokens is tiktoken's cl100k_base.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-qp257djs
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py verify.py context.py window.py sweep.py alike.py removed.py squeeze.py squeezed.py order.py headers.py compare.py three.py
lab exec 'python ingest.py' >/dev/null

block window
on 'python window.py "How long is a gift card valid?"'
block sweep
on 'python sweep.py'
block alike
on 'python alike.py "When can an audiobook be refunded?"'
on 'python removed.py'
block squeeze
on 'python squeeze.py dev'
on 'python squeeze.py held-out'
on 'python squeezed.py "How long after my return arrives will I get the refund?"'
on 'python squeezed.py "Can I return a signed copy?"'
block order
on 'python order.py'
block headers
on 'python headers.py'
block three
on 'python three.py "How long is a gift card valid?"'
block compare
on 'python compare.py'
