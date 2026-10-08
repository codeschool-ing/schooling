#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of rag, as a script that produces
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
# (1b226e2802db). The one reply no model wrote is made_up.py's, and the
# program and the lesson both say so.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-25gk67qg
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py verify.py show_prompt.py made_up.py check_reply.py no_floor.py floor.py clause.py
lab exec 'python ingest.py' >/dev/null

block prompt
on 'python show_prompt.py "How long after my return arrives will I get the refund?"'
block answer-refund
on 'python answer.py "How long after my return arrives will I get the refund?"'
block made-up
on 'python made_up.py'
block check-refund
on 'python check_reply.py "How long after my return arrives will I get the refund?"'
block signed
on 'python answer.py "Can I return a signed copy?"'
on 'python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"'
on 'python check_reply.py "Can I return a signed copy?"'
block no-floor
on 'python no_floor.py "Can I place an order by phone?"'
block refuse
on 'python answer.py "Can I place an order by phone?"'
on 'python answer.py "Is there a student discount?"'
on 'python answer.py "Can I pay in instalments?"'
block floor
on 'python floor.py | sort -r | sed -n "22,30p"'
block conflict-loose
on 'python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"'
block conflict-filtered
on 'python answer.py "How many days do I have to return a printed book?"'
block clause
on 'python clause.py "When is the contract of sale formed?"'
