#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of rag, as a script that produces
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
# (1b226e2802db). The assistant role logs in over localhost with the password
# policy.sql gives it, as a student's would; the role survives between runs,
# because roles belong to the server and the reset drops only the database.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-hcpmrbe9
lab reset $L >/dev/null
use vectors.py chunking.py ingest.py search.py answer.py access.py policy.sql roles.py after.py asassistant.py index.py narrow.py audit.py deleted.py
lab exec 'python ingest.py' >/dev/null

block roles
on 'python roles.py "When does an order get held for manual fraud review?" customer agent finance'
block roles2
on 'python roles.py "What happens to an order that looks fraudulent?" agent finance'
block after
on 'python after.py agent "When does an order get held for manual fraud review?"'
block rls
on 'psql -q -f policy.sql'
on 'python asassistant.py'
on 'python asassistant.py public'
on 'python asassistant.py public,staff'
block index
on 'psql -qc "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"'
on 'python index.py "When does an order get held for manual fraud review?"'
on 'psql -qc "DROP INDEX chunks_embedding_idx"'
block narrow
on 'python narrow.py customer finance "How many refunds can I get before my account is flagged?"'
on 'python narrow.py seller sellers "How long do I have to dispatch an order?"'
block flag
on 'python roles.py "How many refunds can I get before my account is flagged?" customer finance'
block audit
on 'python audit.py'
on 'python audit.py --careless'
block deleted
on 'python deleted.py'
on 'rm data/docs/warehouse-runbook.md && python ingest.py'
on 'python deleted.py'
