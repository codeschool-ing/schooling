#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every summary is
# llama3.2:3b (Ollama tag a80c4f17acd5) at temperature 0, served by Ollama
# 0.40.0 on four processors and no graphics card. The essentials essentials.py
# checks for were written by a person who read the conversation.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-9qsjh9d9
lab reset $L >/dev/null
use vectors.py chunking.py search.py memory.py compact.py essentials.py one.py summaries.py compacted.py rolling.py policy.py

block one
on 'python one.py 40'
block summaries
on 'python summaries.py'
block compacted
on 'python compacted.py'
block rolling
on 'python rolling.py'
block policy-items
on 'python policy.py "Items that cannot be returned" 25'
block policy-gifts
on 'python policy.py "Gifts" 25'
