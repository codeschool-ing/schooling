#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of rag, as a script that produces
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
# 0.40.0 on four processors and no graphics card; every embedding is all-minilm
# (1b226e2802db), reached through Haystack's OpenAI components. RAGFlow is a
# server application of its own and is described, not run.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# haystack-ai 3.3.0, TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-azyaaxc2
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py hs_docs.py hs_index.py hs_floor.py hs_ask.py hs_wrong.py hs_dump.py hs_measure.py
lab exec 'python ingest.py' >/dev/null

block index
on 'python hs_index.py'
on 'python hs_index.py --overwrite'
block ask
on 'python hs_ask.py "How many days do I have to return a printed book?"'
on 'python hs_ask.py "Can I pay with cryptocurrency?"'
block wrong
on 'python hs_wrong.py'
block dump
on 'python hs_dump.py > rag.yaml; wc -l rag.yaml'
on 'head -n 18 rag.yaml'
on 'grep -n -A 11 "      filters:" rag.yaml'
on 'sed -n "/^connections:/,\$p" rag.yaml'
block measure
on 'python hs_measure.py'
