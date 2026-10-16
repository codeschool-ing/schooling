#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, and
# the activation model as lesson 7 leaves it, each taken out of the earlier
# lessons' .md files. tracking.sql is taken out of tracking-check.md, and the audience view out of
# audiences.md. Hightouch,
# Census and Segment are not run: the lesson describes them from their
# documentation and says so.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
in_home() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "cd ~ && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
views_up_to 3 >/dev/null 2>&1
python3 "$FENCE" ../le-zpnh1qs0/the-model.md '-- activation.sql' | lab exec 'psql -q lantern' >/dev/null 2>&1
python3 "$FENCE" tracking-check.md '-- tracking.sql' | lab exec 'cat > ~/tracking.sql'

block plan-load
in_home 'psql -q lantern -f tracking.sql'

block unplanned
session lantern <<'SQL'
SELECT i.event, count(*) AS events
FROM tracking.incoming i LEFT JOIN tracking.plan p USING (event)
WHERE p.event IS NULL
GROUP BY i.event;
SQL

block duplicates
session lantern <<'SQL'
SELECT event, count(*) AS events,
       count(DISTINCT (session_id, happened_at)) AS distinct_events
FROM tracking.incoming
GROUP BY event
HAVING count(*) > count(DISTINCT (session_id, happened_at));
SQL

block out-of-order
session lantern <<'SQL'
SELECT p.step, p.event, count(DISTINCT i.session_id) AS sessions_without_the_step_before
FROM tracking.incoming i JOIN tracking.plan p USING (event)
WHERE p.step > 1
  AND NOT EXISTS (SELECT 1 FROM tracking.incoming j JOIN tracking.plan q USING (event)
                  WHERE j.session_id = i.session_id AND q.step = p.step - 1)
GROUP BY p.step, p.event ORDER BY p.step;
SQL

block funnel-day
session lantern <<'SQL'
SELECT p.step, p.event,
       count(DISTINCT i.session_id) FILTER (WHERE i.device = 'desktop') AS desktop,
       count(DISTINCT i.session_id) FILTER (WHERE i.device = 'mobile') AS mobile
FROM tracking.plan p LEFT JOIN tracking.incoming i USING (event)
GROUP BY p.step, p.event ORDER BY p.step;
SQL

block audience-health
session lantern <<'SQL'
SELECT health, count(*) AS customers, sum(net_revenue) AS net_revenue
FROM activation.crm_contacts
WHERE segment = 'office'
GROUP BY health ORDER BY 2 DESC;
SQL

block audience
{ python3 "$FENCE" audiences.md 'CREATE VIEW activation.office_win_back'
  cat <<'SQL'
SELECT count(*) AS customers, sum(net_revenue) AS net_revenue,
       min(last_order) AS earliest, max(last_order) AS latest
FROM activation.office_win_back;
SQL
} | session lantern
