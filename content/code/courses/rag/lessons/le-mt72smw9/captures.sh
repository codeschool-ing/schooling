#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of rag, as a script that produces
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
# (1b226e2802db), reached through LangChain's and LlamaIndex's OpenAI classes.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# LangChain and LlamaIndex at the versions in lesson 1's requirements.txt,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-mt72smw9
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py lc_split.py lc_embed.py lc_load.py lc_search.py lc_chain.py li_where.py li_setup.py li_ask.py li_cite.py li_window.py li_merge.py frameworks.py
lab exec 'python ingest.py' >/dev/null

block split
on 'python lc_split.py | head -n 20'
block embed
on 'python lc_embed.py'
block load
on 'python lc_load.py'
on 'psql -c "\dt"'
on 'python lc_load.py'
on 'psql -Atc "SELECT count(*) FROM langchain_pg_embedding"'
on 'psql -qc "DELETE FROM langchain_pg_embedding"'
on 'python lc_load.py --ids'
on 'python lc_load.py --ids'
on 'psql -Atc "SELECT count(*) FROM langchain_pg_embedding"'
block search
on 'python lc_search.py "How long is a gift card valid?"'
block chain
on 'python lc_chain.py --all "How many days do I have to return a printed book?"'
on 'python lc_chain.py "How many days do I have to return a printed book?"'
on 'python lc_chain.py "Can I pay with cryptocurrency?"'
block where
on 'python li_where.py'
block ask
on 'python li_ask.py "How long is a gift card valid?" "How many days do I have to return a printed book?"'
block cite
on 'python li_cite.py "How long is a gift card valid?"'
block window
on 'python li_window.py "How much is express delivery?"'
block merge
on 'python li_merge.py "On how many devices can I read my e-books?"'
block measure
on 'python frameworks.py'
