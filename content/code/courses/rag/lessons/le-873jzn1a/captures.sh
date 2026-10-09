#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every vector is
# all-minilm (Ollama tag 1b226e2802db) served by Ollama 0.40.0, through the
# OpenAI SDK; this lesson calls no generator. Port 11435 has nothing listening
# on it, on purpose: it is the refusal the section on refusals shows.
#
# Recorded on Ubuntu 24.04, Python 3.12, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-873jzn1a
lab reset $L >/dev/null
use vectors.py chunking.py header.py ingest.py check_index.py

block header
on 'python header.py'
block batches
on 'OPENAI_LOG=info python ingest.py 2>&1 | grep -c "HTTP Request"'
on 'psql -tc "SELECT count(*) FROM chunks"'
block refusals
on 'psql -qc "DROP TABLE chunks"'
on 'OPENAI_BASE_URL=http://localhost:11435/v1 OPENAI_LOG=info python ingest.py 2>&1 | grep -E "Retrying|Error:"'
on 'psql -tc "SELECT count(*) FROM chunks"'
on 'python ingest.py'
block table-d
on 'psql -c "\d chunks"'
block table-rows
on 'psql -c "SELECT doc_id, count(*) AS chunks, sum(tokens) AS tokens FROM chunks GROUP BY doc_id ORDER BY doc_id"'
on 'psql -c "SELECT id, path, status, audience FROM chunks WHERE doc_id = '"'"'returns-policy'"'"' ORDER BY position LIMIT 4"'
block check-first
on 'python check_index.py; echo "exit $?"'
block ids-rerun
on 'python ingest.py'
block ids-edit
on 'sed -i "s/We refund within three working days/We refund within two working days/" data/docs/returns-policy.md'
on 'python ingest.py'
block supersede
on 'sed -i "s/^status: current$/status: superseded/" data/docs/gift-cards.md'
on 'python ingest.py'
on 'psql -c "SELECT status, count(*) FROM chunks GROUP BY status"'
block remove
on 'rm data/docs/returns-policy-2025.md'
on 'python ingest.py'
on 'psql -tc "SELECT count(*) FROM chunks WHERE doc_id = '"'"'returns-policy-2025'"'"'"'
block index
on 'psql -c "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"'
on 'psql -c "SET enable_seqscan = off" -c "EXPLAIN (COSTS OFF) SELECT path FROM chunks ORDER BY embedding <=> (SELECT embedding FROM chunks LIMIT 1) LIMIT 3"'
block check-last
on 'python check_index.py; echo "exit $?"'
