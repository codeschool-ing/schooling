#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh            # about ten minutes: two full syncs
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, each
# taken out of the earlier lessons' .md files. crm.py is taken out of the
# schooling-example in the-crm.md, joined the way the copy button joins it;
# activation.sql, sync.sh and the new order are taken out of this lesson's
# other .md files. The CRM runs as ana in the background, where the student
# runs it in a second terminal.
#
# The number of 429 retries a full sync makes depends on how fast this
# machine runs psql and curl, so it differs between runs and between
# machines; the lesson says so where it quotes one.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Python 3.12, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
EXAMPLE=../../lab/example.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
in_dir() { printf 'ana@vm:~/reverse$ %s\n' "$*"; lab exec "cd ~/reverse && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
lab exec 'pkill -f "python3 crm.py"' >/dev/null 2>&1
views_up_to 3 >/dev/null 2>&1
lab exec 'rm -rf ~/reverse && mkdir -p ~/reverse'
python3 "$EXAMPLE" the-crm.md crm.py | lab exec 'cat > ~/reverse/crm.py'
python3 "$FENCE" the-model.md '-- activation.sql' | lab exec 'cat > ~/reverse/activation.sql'
python3 "$EXAMPLE" first-sync.md sync.sh | lab exec 'cat > ~/reverse/sync.sh'
crm_up() { lab exec 'cd ~/reverse && (setsid python3 crm.py > /tmp/abi-crm.log 2>&1 < /dev/null &)'
  until curl -s localhost:8000/stats >/dev/null 2>&1; do sleep 0.5; done; }

crm_up
block crm-empty
in_dir "curl -s -w '\\n' localhost:8000/stats"

block model-load
in_dir 'psql -q lantern -f activation.sql'

block model-rows
session lantern <<'SQL'
SELECT * FROM activation.crm_contacts
WHERE external_id IN ('lantern-2', 'lantern-10', 'lantern-1500');
SELECT health, count(*) FROM activation.crm_contacts GROUP BY health ORDER BY 2 DESC;
SQL

block first-sync
in_dir 'bash sync.sh'
block first-stats
in_dir "curl -s -w '\\n' localhost:8000/stats"
block one-contact
in_dir "curl -s -w '\\n' 'localhost:8000/contacts?external_id=lantern-1500'"

block second-sync
in_dir 'bash sync.sh'

block new-order
python3 "$FENCE" diffing.md 'INSERT INTO shop.orders' | session lantern
block changed
session lantern <<'SQL'
SELECT m.external_id, s.payload ->> 'health' AS sent, m.health AS now
FROM activation.crm_contacts m JOIN activation.last_sent s USING (external_id)
WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb;
SQL
block third-sync
in_dir 'bash sync.sh'
in_dir "curl -s -w '\\n' 'localhost:8000/contacts?external_id=lantern-1500'"

block post-twice
python3 "$FENCE" match-keys.md 'curl -s -X POST' > /tmp/abi-post.sh; chmod 644 /tmp/abi-post.sh
printf 'ana@vm:~/reverse$ bash post-twice.sh\n'; lab exec 'cd ~/reverse && bash /tmp/abi-post.sh' 2>&1
in_dir "curl -s -w '\\n' 'localhost:8000/contacts?external_id=lantern-10'"

block erase
session lantern <<'SQL'
DELETE FROM shop.customers WHERE customer_id = 2;
SQL
in_dir 'bash sync.sh'
in_dir "curl -s -w '\\n' 'localhost:8000/contacts?external_id=lantern-2'"

block burst
python3 "$FENCE" rate-limits.md 'for i in' > /tmp/abi-burst.sh; chmod 644 /tmp/abi-burst.sh
printf 'ana@vm:~/reverse$ bash burst.sh\n'; lab exec 'cd ~/reverse && bash /tmp/abi-burst.sh' 2>&1

block new-value
python3 "$FENCE" when-the-sync-fails.md 'CREATE OR REPLACE VIEW activation.crm_contacts' | session lantern
in_dir 'bash sync.sh 2>&1 | tail -n 4'

block log
session lantern <<'SQL'
SELECT run_id, action, http_status, count(*)
FROM activation.sync_log GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;
SQL

lab exec 'pkill -f "python3 crm.py"' >/dev/null 2>&1
