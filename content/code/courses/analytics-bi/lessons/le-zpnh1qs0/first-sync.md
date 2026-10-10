---
title: The first sync
version: 1
---

The sync is a short shell script: `psql` reads the model, `curl` sends each contact, and `psql`
writes down what happened. Save it as `~/reverse/sync.sh`, with the copy button again:

```schooling-example
{"language": "sh", "file": "sync.sh", "parts": [{"code": "#!/usr/bin/env bash\n# sync.sh: send what changed in activation.crm_contacts to the CRM, and remember it.\nset -u\nCRM=http://localhost:8000\ndb() { psql -qAtX -v ON_ERROR_STOP=1 lantern \"$@\"; }\nRUN=$(db -c \"SELECT coalesce(max(run_id), 0) + 1 FROM activation.sync_log\")\nsent=0; removed=0; failed=0; retried=0", "note": "`db` runs one statement in `lantern` and prints the bare result. Each run gets a number one higher than the last in the log, and four counters."}, {"code": "send() {                        # send METHOD ID [PAYLOAD]; sets $code, retries a 429\n  for attempt in 1 2 3 4 5; do\n    code=$(curl -s -o /tmp/crm-reply -w '%{http_code}' -X \"$1\" \"$CRM/contacts/$2\" \\\n           -H 'Content-Type: application/json' ${3:+-d \"$3\"})\n    [ \"$code\" = 429 ] || return 0\n    retried=$((retried + 1)); sleep 1\n  done\n}", "note": "`send` makes one request with `curl` and keeps its status code in `code`. On `429` it waits a second and tries again, up to five times."}, {"code": "log() {                         # log ID ACTION\n  db -v run=\"$RUN\" -v id=\"$1\" -v action=\"$2\" -v code=\"$code\" <<'SQL'\nINSERT INTO activation.sync_log (run_id, external_id, action, http_status)\nVALUES (:run, :'id', :'action', :code);\nSQL\n}", "note": "Every attempt is written to `sync_log`: which run, which contact, what was done, what the CRM answered. The values go in as psql variables, `:'id'`, which quotes them safely."}, {"code": "while IFS=$'\\t' read -r id payload; do\n  send PUT \"$id\" \"$payload\"; log \"$id\" upsert\n  if [ \"$code\" = 200 ] || [ \"$code\" = 201 ]; then\n    db -v id=\"$id\" -v payload=\"$payload\" <<'SQL'\nINSERT INTO activation.last_sent VALUES (:'id', :'payload', now())\nON CONFLICT (external_id) DO UPDATE SET payload = EXCLUDED.payload, sent_at = now();\nSQL\n    sent=$((sent + 1))\n  else\n    failed=$((failed + 1)); echo \"$id: HTTP $code $(cat /tmp/crm-reply)\"\n  fi\ndone < <(db -F $'\\t' -c \"\n  SELECT m.external_id, row_to_json(m)\n  FROM activation.crm_contacts m LEFT JOIN activation.last_sent s USING (external_id)\n  WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb\n  ORDER BY m.external_id\")", "note": "The first loop reads the contacts whose current row differs from what was last sent — the diff — and PUTs each one. Only after the CRM accepts it is the row remembered in `last_sent`; a failure is printed and left to be tried again next run."}, {"code": "while read -r id; do\n  send DELETE \"$id\"; log \"$id\" delete\n  if [ \"$code\" = 200 ] || [ \"$code\" = 404 ]; then\n    db -v id=\"$id\" <<<\"DELETE FROM activation.last_sent WHERE external_id = :'id';\"\n    removed=$((removed + 1))\n  else\n    failed=$((failed + 1)); echo \"$id: HTTP $code $(cat /tmp/crm-reply)\"\n  fi\ndone < <(db -c \"\n  SELECT s.external_id FROM activation.last_sent s\n  WHERE NOT EXISTS (SELECT 1 FROM activation.crm_contacts m WHERE m.external_id = s.external_id)\n  ORDER BY 1\")", "note": "The second loop finds contacts that were sent before and are no longer in the model, and deletes them from the CRM. A `404` counts as done: it was not there anyway."}, {"code": "echo \"run $RUN: sent $sent, removed $removed, failed $failed, retried after 429: $retried\"", "note": "One line says what the run did."}]}
```

Run it. The first time, every contact is new, so every contact is sent, one request after another —
2,649 of them, a few minutes' work:

```
ana@vm:~/reverse$ bash sync.sh
run 1: sent 2649, removed 0, failed 0, retried after 429: 254
```

Everything sent and nothing failed. The last number is how many requests the CRM refused for coming
too fast and the script repeated after a second's pause; it depends on how fast your machine runs, so
yours will differ. The CRM's side of it:

```
ana@vm:~/reverse$ curl -s -w '\n' localhost:8000/stats
{"requests": 2903, "refused": 254, "contacts": 2649}
```

And one contact, as the CRM now holds it:

```
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-1500'
[{"external_id": "lantern-1500", "segment": "home", "region": "Southeast", "orders": 6, "net_revenue": 553.22, "last_order": "2026-01-18", "health": "lapsed", "crm_id": 558}]
```

Customer 1500 is in the CRM with every field of the model, plus `crm_id`, the CRM's own number for the
record. A salesperson opening that contact sees *lapsed*, six orders and R$ 553.22, without anybody
having exported anything.
