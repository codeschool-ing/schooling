#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py and answer.py live in ../../lab/code and
# are lessons 4 to 7's; memory.py and chat.py, there too, are this lesson's.
# The two conversations are data/chat-a.jsonl and data/chat-b.jsonl, written
# for the course: the customers, their orders and their address are invented.
# The two accounts, A-1001 and A-1002, are a dictionary in chat.py standing in
# for the shop's account table. Every reply comes from extract-1, the lab's
# stand-in generator, which is not a language model (lab/labgen.py says what
# it does); the token counts are labgen's, reported in each reply's usage.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
use chunking.py ingest.py search.py answer.py memory.py chat.py
lab exec 'python ingest.py' >/dev/null
put condense.py <<'EOF_FILE'
from llama_index.core.chat_engine.condense_question import DEFAULT_TEMPLATE

print(DEFAULT_TEMPLATE)
EOF_FILE
put recalled.py <<'EOF_FILE'
import json
import sys

import memory

chat, account = sys.argv[1], sys.argv[2]
turns = [json.loads(line)["text"] for line in open(f"data/{chat}.jsonl")]
for n in map(int, sys.argv[3:]):
    print(f"turn {n}: {turns[n - 1]}")
    for turn, text, score in memory.recall(account, turns[n - 1], 2, before=n):
        print(f"   {score:.3f}  turn {turn}: {text}")
EOF_FILE
put careless.py <<'EOF_FILE'
import sys

from memory import ORDER
from search import conn

# memory.state, written without the account.
said = " ".join(t for (t,) in conn.execute("SELECT text FROM memories ORDER BY turn"))
orders = list(dict.fromkeys(ORDER.findall(said)))
print(f"You are {sys.argv[1]}. Your order number is {' and '.join(orders)}.")
EOF_FILE
put remembered.py <<'EOF_FILE'
import sys

from search import conn

for turn, text in conn.execute("SELECT turn, text FROM memories WHERE account = %s ORDER BY turn",
                               (sys.argv[1],)):
    print(f"{turn:2}  {text}")
EOF_FILE

block alone
on 'python chat.py chat-a alone'
block history
on 'python chat.py chat-a history'
block condense
on 'python condense.py'
block recall
on 'python chat.py chat-a memory > /dev/null'
on 'python recalled.py chat-a A-1001 10 11 12'
block memory
on 'python chat.py chat-a memory'
block state
on 'python -c "import memory; print(memory.state(\"A-1001\", \"Beatriz Costa\"))"'
on 'python chat.py chat-b memory'
block accounts
on 'python careless.py "Rafael Lima"'
on 'python recalled.py chat-b A-1002 4'
block forget
on 'psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"'
on 'python remembered.py A-1002'
on 'python -c "import memory; print(memory.forget(\"A-1002\"), \"rows deleted\")"'
on 'psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"'
