#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of rag, as a script that produces
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
# all-minilm (1b226e2802db). The instruction in listing L04 is a canary written
# for the course: harmless, and visible in the reply when it is obeyed.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-zeczwgpv
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py verify.py memory.py chat.py listings.py delimited.py scan.py checked.py mixed.py pasted.py
lab exec 'python ingest.py' >/dev/null
python3 "$COURSE/lab/shown.py" "$COURSE" listings.sh $L > /home/ana/rag/listings.sh

block listings-sh
on 'sh listings.sh'
on 'wc -l data/listings.jsonl'
block canary
on 'python listings.py "Which copy of Emma is for sale, and in what condition?"'
on 'python listings.py "Which copies were bought as a gift?"'
block delimited
on 'python delimited.py "Which copy of Emma is for sale, and in what condition?"'
block scan
on 'python scan.py'
block checked
on 'python checked.py "Which copy of Emma is for sale, and in what condition?"'
block mixed
on 'python mixed.py "How many days do I have to return a printed book?"'
block pasted
on 'python pasted.py history'
on 'python pasted.py memory'
