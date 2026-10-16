# Sourced by the capture scripts of lessons 3 to 9: Metabase in Docker, run the
# way lesson 3 tells the student to run it, and set up through its API with the
# same answers lesson 3 gives in its setup screens (a person, the database
# lantern through the role metabase, the schema semantic only). The student
# types those answers into the browser; the API is how the lab types them.
MB=http://localhost:3000
MB_IMAGE=metabase/metabase:v0.64.1.5

mb_fresh() {
  docker rm -f metabase >/dev/null 2>&1
  docker volume rm metabase-data >/dev/null 2>&1
  docker run -d --name metabase --network host --restart unless-stopped \
    -e JAVA_OPTS=-Xmx1g -v metabase-data:/metabase-data \
    -e MB_DB_FILE=/metabase-data/metabase.db "$MB_IMAGE" >/dev/null
  mb_wait
}

mb_wait() { until curl -sf "$MB/api/health" >/dev/null; do sleep 2; done; }

mb_setup() {
  local token
  token=$(curl -s "$MB/api/session/properties" | python3 -c 'import json,sys; print(json.load(sys.stdin)["setup-token"])')
  curl -s -X POST "$MB/api/setup" -H 'Content-Type: application/json' -d "{
    \"token\": \"$token\",
    \"user\": {\"first_name\": \"Ana\", \"last_name\": \"Souza\", \"email\": \"ana@example.com\",
              \"password\": \"a-long-passphrase-for-ana-2026\", \"site_name\": \"Lantern Coffee\"},
    \"prefs\": {\"site_name\": \"Lantern Coffee\", \"site_locale\": \"en\", \"allow_tracking\": false}}" >/dev/null
  MB_TOKEN=$(mb_login)
  curl -s -X POST "$MB/api/database" -H 'Content-Type: application/json' -H "X-Metabase-Session: $MB_TOKEN" -d '{
    "engine": "postgres", "name": "Lantern",
    "details": {"host": "localhost", "port": 5432, "dbname": "lantern", "user": "metabase",
                "password": "pick-your-own-password",
                "schema-filters-type": "inclusion", "schema-filters-patterns": "semantic"}}' >/dev/null
  # wait for the first sync to have seen the tables
  local i n
  for i in $(seq 90); do
    n=$(mb_get /api/database/2/metadata | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("tables",[])))' 2>/dev/null)
    [ "${n:-0}" -ge 6 ] && return 0
    sleep 2
  done
  echo "metabase: the database synced no tables — are the grants to metabase in place?" >&2
  return 1
}

mb_login() {
  curl -s -X POST "$MB/api/session" -H 'Content-Type: application/json' \
    -d '{"username": "ana@example.com", "password": "a-long-passphrase-for-ana-2026"}' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
}

mb_get() { curl -s -H "X-Metabase-Session: ${MB_TOKEN:-$(mb_login)}" "$MB$1"; }
mb_post() { curl -s -X POST -H 'Content-Type: application/json' -H "X-Metabase-Session: ${MB_TOKEN:-$(mb_login)}" "$MB$1" -d "$2"; }
