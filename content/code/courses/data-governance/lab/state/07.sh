# Where lesson 7 leaves the lab: sales.consent_events and the view
# sales.consent_now (customer 1 withdrew on 20 June); the job privacy_officer
# for davi, with reads across the schemas and the OpenBao policy dpo;
# gov.subject_requests with four requests; customer 3 erased as far as the
# law allows; and a service entry for davi.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "cd $GOV && $1"
}
pg <<'SQL'
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
INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at)
VALUES (1, 'marketing-email', false, 'mkt-v1', 'unsubscribe link', '2026-06-20 09:12:00-03');
RESET ROLE;
SET ROLE ana;
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
RESET ROLE;
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
SQL
as_ana 'printf "%s\n" "path \"transit/decrypt/ipe-cpf\" {" "  capabilities = [\"update\"]" "}" | bao policy write dpo - >/dev/null'
printf '\n[davi]\nhost=db.ipe.example\nport=5433\ndbname=ipe\nuser=davi\nsslmode=verify-full\n' >> /home/ana/.pg_service.conf
