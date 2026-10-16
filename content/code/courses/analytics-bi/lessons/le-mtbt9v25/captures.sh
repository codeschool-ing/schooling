#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop, the semantic layer and Metabase as lesson 3 leaves
# them, each taken out of the earlier lessons' .md files. app.py is taken out
# of the schooling-example in streamlit-app.md (joined the way the copy button
# joins it), and secrets.toml, config.toml and the role out of the same files.
#
# Tableau and Looker were not run: both are commercial products, and the LookML
# in the lesson is written from Looker's documentation and says so.
#
# STAGED: what a browser shows. Metabase is set up through its API with the
# answers lesson 3 gives; the foreign key the lesson sets in Table Metadata is
# set through the same API; the SQL in `fk-sql` is what Metabase returned for
# the question the lesson builds. What the Streamlit page shows is read by a
# headless Chromium (lab/page.mjs), which is the block `page`. python3 is
# Ubuntu's 3.12, as a fresh install has it.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Streamlit 1.65.0, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
EXAMPLE=../../lab/example.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
in_app() { printf 'ana@vm:~/revenue$ %s\n' "$*"; lab exec "cd ~/revenue && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
page() { node ../../lab/page.mjs "$@" 2>&1 | grep -v '^\[agent-proxy\]\|connect_rejected\|For details\|^- ' ; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
. ../../lab/metabase.sh
pkill -9 -u ana -f /home/ana/st/bin/streamlit
views_up_to 3 >/dev/null 2>&1
lab exec "psql -qX lantern -c 'DROP ROLE IF EXISTS streamlit_app'" >/dev/null 2>&1
lab exec 'rm -rf ~/st ~/revenue'
mb_fresh 9>&-; mb_setup >/dev/null

# ---- Metabase: the foreign key, and the question it makes possible
MB_TOKEN=$(mb_login)
META=$(mb_get /api/database/2/metadata)
fid() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); t=[t for t in d['tables'] if t['name']==sys.argv[2]][0]; print([f['id'] for f in t['fields'] if f['name']==sys.argv[3]][0])" "$META" "$1" "$2"; }
tid() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); print([t['id'] for t in d['tables'] if t['name']==sys.argv[2]][0])" "$META" "$1"; }
O_CUST=$(fid orders customer_id); C_CUST=$(fid customers customer_id); C_SEG=$(fid customers segment)
O_NET=$(fid orders net_revenue); ORDERS=$(tid orders)
curl -s -X PUT -H 'Content-Type: application/json' -H "X-Metabase-Session: $MB_TOKEN" "$MB/api/field/$C_CUST" -d '{"semantic_type":"type/PK"}' >/dev/null
curl -s -X PUT -H 'Content-Type: application/json' -H "X-Metabase-Session: $MB_TOKEN" "$MB/api/field/$O_CUST" -d "{\"semantic_type\":\"type/FK\",\"fk_target_field_id\":$C_CUST}" >/dev/null
Q="{\"database\":2,\"type\":\"query\",\"query\":{\"source-table\":$ORDERS,\"aggregation\":[[\"sum\",[\"field\",$O_NET,null]]],\"breakout\":[[\"field\",$C_SEG,{\"source-field\":$O_CUST}]]}}"
mb_post /api/dataset/native "$Q" | python3 -c 'import json,sys; print(json.load(sys.stdin)["query"])' > /tmp/abi-fk.sql
chmod 644 /tmp/abi-fk.sql

block fk-sql
cat /tmp/abi-fk.sql

block fk-run
printf 'ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f segment.sql\n'
lab exec 'PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f /tmp/abi-fk.sql' 2>&1

# ---- Streamlit
block venv
on 'python3 -m venv ~/st'
on '~/st/bin/pip install -q streamlit==1.65.0 "psycopg[binary]==3.3.6"'
on '~/st/bin/streamlit version'
on 'du -sh ~/st'

block role
python3 "$FENCE" streamlit-setup.md 'CREATE ROLE streamlit_app' | session lantern

lab exec 'mkdir -p ~/revenue/.streamlit'
python3 "$EXAMPLE" streamlit-app.md app.py | lab exec 'cat > ~/revenue/app.py'
python3 "$FENCE" streamlit-app.md '[db]' | lab exec 'cat > ~/revenue/.streamlit/secrets.toml'
python3 "$FENCE" streamlit-app.md '[browser]' | lab exec 'cat > ~/revenue/.streamlit/config.toml'

block tree
in_app 'find . -type f | sort'

lab exec 'cd ~/revenue && (setsid ~/st/bin/streamlit run app.py > /tmp/abi-st.log 2>&1 < /dev/null &)'
until curl -sf http://localhost:8501/_stcore/health >/dev/null; do sleep 1; done
block health
on "curl -s -w '\\n' http://localhost:8501/_stcore/health"

block page
page metric-both
block page-office
page metric-office

# ---- when it fails
block not-found
in_app 'streamlit run app.py'

block second
in_app 'timeout -s KILL 20 ~/st/bin/streamlit run app.py 2>&1 | grep -o "server started on .*"'

restart() { pkill -9 -u ana -f /home/ana/st/bin/streamlit; sleep 2
  lab exec 'cd ~/revenue && (setsid ~/st/bin/streamlit run app.py > /tmp/abi-st.log 2>&1 < /dev/null &)'
  until curl -sf http://localhost:8501/_stcore/health >/dev/null; do sleep 1; done; }

block no-secrets
lab exec 'mv ~/revenue/.streamlit/secrets.toml ~/revenue/.streamlit/secrets.toml.away'
restart; page load
grep 'StreamlitSecretNotFoundError' /tmp/abi-st.log | tail -n 1
lab exec 'mv ~/revenue/.streamlit/secrets.toml.away ~/revenue/.streamlit/secrets.toml'

block bad-password
lab exec "sed -i 's/a-third-password-to-choose/wrong/' ~/revenue/.streamlit/secrets.toml"
restart; page load
grep 'OperationalError' /tmp/abi-st.log | tail -n 1
python3 "$FENCE" streamlit-app.md '[db]' | lab exec 'cat > ~/revenue/.streamlit/secrets.toml'

pkill -9 -u ana -f /home/ana/st/bin/streamlit
