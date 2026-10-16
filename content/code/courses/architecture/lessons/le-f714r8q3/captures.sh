#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The six files of ~/lab/search are EXTRACTED from the section "The lab:
# OpenSearch beside the database" (the-lab.md), as the copy button hands them
# over, and so is the variable R that section defines. Staged: the tools image
# is built beforehand (lab.sh, "prebuild"); OpenSearch gets forty seconds to
# start, and the first search waits six seconds after the first feed so that
# the refresh section is the only place the refresh shows. Recorded on Ubuntu
# 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-f714r8q3
lab reset
at '~/lab/search'
for f in seed.sql index.json feed.py search.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/search/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^R=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
rrun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 40
Q='docker compose exec -T db psql -U postgres'
block up
rrun 'curl -s "localhost:9200/?filter_path=version.distribution,version.number,version.lucene_version"; echo'
block feed
rrun '$R feed.py'
block analyze
rrun "curl -s 'localhost:9200/products/_analyze?filter_path=tokens.token' -H 'Content-Type: application/json' -d '{\"field\": \"name\", \"text\": \"Cafés torrados em grãos\"}'; echo"
sleep 6
block search
rrun '$R search.py café torrado'
block ilike
rrun "$Q -c \"SELECT name FROM products WHERE name ILIKE '%cafe torrado%'\" -c \"SELECT name FROM products WHERE name ILIKE '%café torrado%'\""
block typo
rrun '$R search.py cafe torado'
block fuzzy
rrun '$R search.py cafe torado --fuzzy'
block stale
rrun "$Q -c \"INSERT INTO products (id, name, category, description, cents) VALUES (25, 'Café gelado em lata', 'café', 'Café com leite gelado, lata de 250 ml.', 690)\""
rrun '$R search.py gelado'
block refresh
rrun '$R feed.py; $R search.py gelado; sleep 5; $R search.py gelado'
block shards
rrun 'curl -s "localhost:9200/_cat/shards/products?v"'
quiet 'docker compose down -v'
