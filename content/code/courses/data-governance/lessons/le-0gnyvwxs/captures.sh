#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 6 leave
# (`lab.sh state 6`); a service entry for davi in ~/.pg_service.conf, written
# the way lesson 2 wrote the others. The requests in gov.subject_requests are
# written by the lesson with fixed dates, so the deadlines do not move with
# the day the capture is run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 6 >/dev/null 2>&1 </dev/null
quiet "printf '\n[davi]\nhost=db.ipe.example\nport=5433\ndbname=ipe\nuser=davi\nsslmode=verify-full\n' >> ~/.pg_service.conf"

block opt-in
on 'psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, marketing_opt_in, consent_at FROM sales.customers WHERE customer_id IN (1, 2, 3) ORDER BY 1"'

put consents.sql <<'EOF'
-- Every consent and every withdrawal, as events that are never edited.
-- The current state is computed from them; nothing overwrites a choice.
SET ROLE ipe_owner;
CREATE TABLE sales.consent_events (
  event_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  integer     NOT NULL REFERENCES sales.customers,
  purpose      text        NOT NULL,   -- what the consent is for
  given        boolean     NOT NULL,   -- true: given, false: withdrawn
  text_version text        NOT NULL,   -- the wording the person saw
  channel      text        NOT NULL,   -- where it happened
  at           timestamptz NOT NULL
);
-- What the old boolean knew, carried over as the first event of each
-- customer who opted in. The wording of 2019 to 2026 is version 1.
INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at)
SELECT customer_id, 'marketing-email', true, 'mkt-v1', 'sign-up form', consent_at
FROM sales.customers WHERE marketing_opt_in;

-- Lesson 6's rule: a new table is classified in the same change.
INSERT INTO gov.column_class VALUES
 ('sales','consent_events','event_id','personal','one choice somebody made'),
 ('sales','consent_events','customer_id','personal','whose choice'),
 ('sales','consent_events','purpose','personal','what they agreed to or refused'),
 ('sales','consent_events','given','personal','the choice'),
 ('sales','consent_events','text_version','none','which wording; the wording is not about anybody'),
 ('sales','consent_events','channel','personal','where they made it'),
 ('sales','consent_events','at','personal','when');

CREATE VIEW sales.consent_now AS
SELECT DISTINCT ON (customer_id, purpose)
       customer_id, purpose, given, text_version, at
FROM sales.consent_events
ORDER BY customer_id, purpose, at DESC, event_id DESC;
EOF
code consents-sql consents.sql
block consents
on 'psql -f consents.sql'

block withdraw
on "psql -c \"SET ROLE ipe_owner\" -c \"INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at) VALUES (1, 'marketing-email', false, 'mkt-v1', 'unsubscribe link', '2026-06-20 09:12:00-03')\""
on 'psql -c "SET ROLE ipe_owner" -c "SELECT * FROM sales.consent_now WHERE customer_id = 1"'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT given, channel, at FROM sales.consent_events WHERE customer_id = 1 ORDER BY at"'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT given, count(*) FROM sales.consent_now WHERE purpose = '"'"'marketing-email'"'"' GROUP BY given"'

put privacy-role.sql <<'EOF'
-- The DPO answers data subjects' requests: he may read what is about a
-- customer, and change nothing.
CREATE ROLE privacy_officer NOLOGIN;
GRANT privacy_officer TO davi;
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales, health, support, gov TO privacy_officer;
GRANT SELECT ON ALL TABLES IN SCHEMA sales, health, support, gov TO privacy_officer;
CREATE POLICY privacy_officer_reads_all ON sales.customers
  FOR SELECT TO privacy_officer USING (true);
CREATE POLICY privacy_officer_reads_all ON support.tickets
  FOR SELECT TO privacy_officer USING (true);
EOF
code privacy-role-sql privacy-role.sql
block privacy-role
on 'psql -f privacy-role.sql'

put dpo.hcl <<'EOF'
# The DPO decrypts a CPF to include it in a data subject's export.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
EOF
code dpo-hcl dpo.hcl
block dpo-token
on 'bao policy write dpo dpo.hcl'
on 'bao token create -policy=dpo -ttl=1h -field=token > dpo.token && wc -c dpo.token'

put export_subject.py <<'EOF'
"""Everything Ipê holds about one customer, as JSON, for a data subject's
request under article 18 of the LGPD. Which tables to read comes from
gov.column_class: a table with a customer_id is about somebody directly, and
a table with an order_id and no customer_id is about them through an order."""
import base64, json, os, ssl, subprocess, sys, urllib.request

ID = int(sys.argv[1])
TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])

def psql(sql):
    out = subprocess.run(["psql", "service=davi", "-X", "-q", "-At", "-c", sql],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out) if out.strip() else None

def decrypt(ct):
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/decrypt/ipe-cpf",
                                 data=json.dumps({"ciphertext": ct}).encode(), method="POST",
                                 headers={"X-Vault-Token": open("dpo.token").read().strip()})
    with urllib.request.urlopen(req, context=TLS) as r:
        return base64.b64decode(json.load(r)["data"]["plaintext"]).decode()

def tables_with(column, without=None):
    no = (f"AND NOT EXISTS (SELECT 1 FROM gov.column_class d WHERE d.table_schema = c.table_schema "
          f"AND d.table_name = c.table_name AND d.column_name = '{without}')") if without else ""
    return psql("SELECT json_agg(DISTINCT c.table_schema || '.' || c.table_name) "
                f"FROM gov.column_class c WHERE c.column_name = '{column}' {no}") or []

where = {t: f"customer_id = {ID}" for t in tables_with("customer_id")}
for t in tables_with("order_id", without="customer_id"):
    where[t] = f"order_id IN (SELECT order_id FROM sales.orders WHERE customer_id = {ID})"

export = {"customer_id": ID, "generated_for": "LGPD art. 18, II", "tables": {}}
for t in sorted(where):
    rows = psql(f"SELECT json_agg(t) FROM {t} t WHERE {where[t]}") or []
    for r in rows:
        r.pop("cpf_hmac", None)
        if r.get("cpf_ct"):
            r["cpf"] = decrypt(r.pop("cpf_ct"))
    export["tables"][t] = rows
json.dump(export, sys.stdout, ensure_ascii=False, indent=1)
print()
EOF
code export-py export_subject.py
block export
on 'python3 export_subject.py 112 > subject-112.json && wc -c subject-112.json'
on "python3 -c \"import json; d = json.load(open('subject-112.json')); print({t: len(r) for t, r in d['tables'].items()})\""
on "python3 -c \"import json; d = json.load(open('subject-112.json')); print(json.dumps(d['tables']['sales.customers'][0], ensure_ascii=False, indent=1))\""

put requests.sql <<'EOF'
-- Every request a data subject makes, with the date the answer is due.
SET ROLE ipe_owner;
CREATE TABLE gov.subject_requests (
  request_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id integer     NOT NULL,
  kind        text        NOT NULL
              CHECK (kind IN ('confirm', 'access', 'correct', 'delete', 'port',
                              'revoke-consent', 'sharing-info')),
  received_on date        NOT NULL,
  due_on      date        GENERATED ALWAYS AS (received_on + 15) STORED,
  answered_on date,
  answer      text
);
INSERT INTO gov.column_class VALUES
 ('gov','subject_requests','request_id','personal','one person''s request'),
 ('gov','subject_requests','customer_id','personal','whose'),
 ('gov','subject_requests','kind','personal','what they asked for'),
 ('gov','subject_requests','received_on','personal','when'),
 ('gov','subject_requests','due_on','none','arithmetic on the date'),
 ('gov','subject_requests','answered_on','personal','when we answered'),
 ('gov','subject_requests','answer','personal','what we did');
GRANT SELECT, INSERT, UPDATE (answered_on, answer) ON gov.subject_requests TO privacy_officer;
INSERT INTO gov.subject_requests (customer_id, kind, received_on, answered_on, answer) VALUES
  (112, 'access', '2026-06-02', '2026-06-09', 'export sent, subject-112.json'),
  (3,  'delete',  '2026-06-20', NULL, NULL),
  (47, 'access',  '2026-06-10', NULL, NULL),
  (88, 'correct', '2026-06-25', NULL, NULL);
EOF
code requests-sql requests.sql
put due.sql <<'EOF'
-- On the lab's today, 1 July 2026: what is open, and what is late.
SELECT request_id, customer_id, kind, received_on, due_on,
       CASE WHEN due_on < DATE '2026-07-01' THEN 'LATE' ELSE 'open' END AS state
FROM gov.subject_requests
WHERE answered_on IS NULL
ORDER BY due_on;
EOF
code due-sql due.sql
block requests
on 'psql -f requests.sql'
on 'psql service=davi -f due.sql'

put erase.sql <<'EOF'
-- Customer 3 asked for their data to be deleted. What goes, and what stays
-- because a law requires it (article 16, I), decided column by column.
SET ROLE ipe_owner;
BEGIN;
-- Consent-based processing ends, and its record stays as proof of what
-- was asked and when.
INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at)
SELECT 3, 'marketing-email', false, 'mkt-v1', 'deletion request 2', '2026-06-20 14:05-03'
WHERE EXISTS (SELECT 1 FROM sales.consent_now
              WHERE customer_id = 3 AND purpose = 'marketing-email' AND given);
UPDATE sales.customers SET marketing_opt_in = false, consent_at = NULL
WHERE customer_id = 3;
-- What only served the relationship: support conversations.
DELETE FROM support.tickets WHERE customer_id = 3;
-- What a tax or health rule requires is kept, and stops being used for
-- anything else: orders, payments and prescriptions stay; the e-mail,
-- which nothing requires, is replaced.
UPDATE sales.customers SET email = 'erased-3@invalid'
WHERE customer_id = 3;
UPDATE gov.subject_requests
   SET answered_on = '2026-06-26',
       answer = 'erased: e-mail, tickets, marketing consent; kept under art. 16, I: orders, payments, prescriptions'
WHERE request_id = 2;
COMMIT;
EOF
code erase-sql erase.sql
block erase-before
on 'psql -c "SET ROLE ipe_owner" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM health.prescriptions WHERE customer_id = 3) AS prescriptions, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"'
block erase
on 'psql -f erase.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, email, marketing_opt_in FROM sales.customers WHERE customer_id = 3" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"'
on 'psql service=davi -f due.sql'

put ripd-facts.sql <<'EOF'
-- The facts section of a data protection impact assessment, computed
-- rather than estimated: how many people, which classes of data, how much.
SET ROLE ipe_owner;
SELECT 'customers'                        AS fact, count(*)::text AS value FROM sales.customers
UNION ALL SELECT 'of whom under 18',
       count(*)::text FROM sales.customers
       WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
UNION ALL SELECT 'customers with a prescription',
       count(DISTINCT customer_id)::text FROM health.prescriptions
UNION ALL SELECT 'prescriptions held', count(*)::text FROM health.prescriptions
UNION ALL SELECT 'oldest prescription', min(issued_on)::text FROM health.prescriptions
UNION ALL SELECT 'sensitive columns', count(*)::text FROM gov.column_class WHERE class = 'sensitive'
UNION ALL SELECT 'roles that read health', string_agg(DISTINCT grantee, ', ')
       FROM information_schema.role_table_grants
       WHERE table_schema = 'health' AND privilege_type = 'SELECT';
EOF
code ripd-sql ripd-facts.sql
block ripd
on 'psql -f ripd-facts.sql'
