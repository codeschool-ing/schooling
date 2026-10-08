# Where lesson 8 leaves the lab: gov.holidays with Brazil's national holidays
# of 2026, the function gov.working_day, and gov.ai_systems with Ipê's four
# AI systems and their class under the AI Act.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg <<'SQL'
-- Two deadlines for one incident: the GDPR's 72 hours, which run through
-- weekends and holidays, and the ANPD's three working days, which do not.
-- The twenty days to complete the information count from the notice.
SET ROLE ipe_owner;
CREATE TABLE gov.holidays (day date PRIMARY KEY, name text NOT NULL);
-- National holidays only. A state or city holiday where the company sits
-- is a row somebody has to add.
INSERT INTO gov.holidays VALUES
 ('2026-01-01', 'Confraternização Universal'), ('2026-04-21', 'Tiradentes'),
 ('2026-05-01', 'Dia do Trabalho'),            ('2026-09-07', 'Independência'),
 ('2026-10-12', 'Nossa Senhora Aparecida'),    ('2026-11-02', 'Finados'),
 ('2026-11-15', 'Proclamação da República'),   ('2026-11-20', 'Consciência Negra'),
 ('2026-12-25', 'Natal');
INSERT INTO gov.column_class VALUES
 ('gov','holidays','day','none','a date in the calendar'),
 ('gov','holidays','name','none','its name');

-- The n-th working day after the day something became known.
CREATE FUNCTION gov.working_day(known timestamptz, n integer) RETURNS date
LANGUAGE sql STABLE AS $$
  SELECT d::date
  FROM generate_series(known::date + 1, known::date + 60, interval '1 day') AS d
  WHERE extract(isodow FROM d) < 6
    AND d::date NOT IN (SELECT day FROM gov.holidays)
  ORDER BY d
  OFFSET n - 1 LIMIT 1
$$;

-- Every AI system Ipê builds or uses, with the AI Act's class and the
-- reason for it written beside it.
CREATE TABLE gov.ai_systems (
  name         text PRIMARY KEY,
  purpose      text NOT NULL,
  ipe_is       text NOT NULL CHECK (ipe_is IN ('provider', 'deployer')),
  ai_act_class text NOT NULL
               CHECK (ai_act_class IN ('prohibited', 'high-risk', 'transparency', 'minimal')),
  why          text NOT NULL,
  personal     boolean NOT NULL,   -- does it process personal data?
  owner        text                -- who answers for it; NULL is a finding
);
INSERT INTO gov.column_class VALUES
 ('gov','ai_systems','name','none','a system'),
 ('gov','ai_systems','purpose','none','what it is for'),
 ('gov','ai_systems','ipe_is','none','Ipê''s role'),
 ('gov','ai_systems','ai_act_class','none','the class'),
 ('gov','ai_systems','why','none','the reasoning'),
 ('gov','ai_systems','personal','none','a yes or no about the system'),
 ('gov','ai_systems','owner','personal','an employee''s name');
INSERT INTO gov.ai_systems VALUES
 ('fraud-score', 'flags orders likely to be fraudulent', 'provider', 'minimal',
  'Annex III 5(b) excludes systems used to detect financial fraud', true, 'bruno'),
 ('support-bot', 'answers customers in the support chat', 'deployer', 'transparency',
  'art. 50(1): people must be told they are talking to an AI system', true, 'carla'),
 ('recommender', 'suggests products on the shop', 'provider', 'minimal',
  'no Annex III use; the LGPD still rules out health categories', true, 'ana'),
 ('cv-screen', 'ranks applicants for pharmacist jobs', 'deployer', 'high-risk',
  'Annex III 4(a): recruitment and selection of people', true, NULL);
SQL
