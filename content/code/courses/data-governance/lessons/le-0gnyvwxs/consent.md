---
title: Consent that can be proven
version: 1
---

Consent is defined in **article 5, XII** as a *free, informed and unequivocal* expression by which the
person agrees to processing for a *determined purpose*. **Article 8** adds four rules that a data model
has to be able to honour:

- **it must be given in writing or by another means that shows the person's will** — a ticked box with
  its wording, not a box that was ticked by default;
- **the controller has the burden of proving it was given properly** (§2) — when, how, to what;
- **generic authorisations are void** (§4) — "you agree to everything" is consent to nothing;
- **it can be withdrawn at any time, free of charge, by a facilitated procedure** (§5).

## What Ipê had

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, marketing_opt_in, consent_at FROM sales.customers WHERE customer_id IN (1, 2, 3) ORDER BY 1"
SET
 customer_id | marketing_opt_in |       consent_at       
-------------+------------------+------------------------
           1 | t                | 2025-01-07 20:54:32-03
           2 | f                | 
           3 | t                | 2022-04-10 11:06:37-03
(3 rows)
```

A boolean and a date. It says customer 1 consented on 7 January 2025, and nothing else: not to what
wording, not through which form, not to which purpose — "marketing" covers e-mail, SMS and a partner's
offers equally. When customer 1 withdraws, the obvious implementation sets the boolean to `false`, and
then **the proof that she ever consented, and the date she withdrew, are both gone**. Article 8, §2
puts the burden of proof on Ipê; this column makes the proof impossible.

## Consent as events

```sql
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
```

```
ana@lab:~/gov$ psql -f consents.sql
SET
CREATE TABLE
INSERT 0 2536
INSERT 0 7
CREATE VIEW
```

Each consent and each withdrawal is a row that is never edited: who, for which purpose, given or
withdrawn, **under which wording** (`text_version`), through which channel, and when. The 2,536
customers who had opted in become 2,536 first events, with the honest wording version for the years
the old form was used. The new table is classified in the same file, because lesson 6's check would
fail otherwise. The current state is a view, computed from the events.

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at) VALUES (1, 'marketing-email', false, 'mkt-v1', 'unsubscribe link', '2026-06-20 09:12:00-03')"
SET
INSERT 0 1
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT * FROM sales.consent_now WHERE customer_id = 1"
SET
 customer_id |     purpose     | given | text_version |           at           
-------------+-----------------+-------+--------------+------------------------
           1 | marketing-email | f     | mkt-v1       | 2026-06-20 09:12:00-03
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT given, channel, at FROM sales.consent_events WHERE customer_id = 1 ORDER BY at"
SET
 given |     channel      |           at           
-------+------------------+------------------------
 t     | sign-up form     | 2025-01-07 20:54:32-03
 f     | unsubscribe link | 2026-06-20 09:12:00-03
(2 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT given, count(*) FROM sales.consent_now WHERE purpose = 'marketing-email' GROUP BY given"
SET
 given | count 
-------+-------
 f     |     1
 t     |  2535
(2 rows)
```

Customer 1 unsubscribed on 20 June. Her current state says `given = f`; her history says when she
consented, through which form, and when and how she withdrew. 2,535 consents stand. Every one of them
can be shown to an inspector with the wording the person saw — which is what article 8 asks, and
what a boolean could never do.

**Withdrawal stops future processing; it does not undo the past.** E-mails sent before 20 June were
sent lawfully. What withdrawal does require is that the marketing system read `consent_now`, not the
old boolean, before the next campaign — and a test that fails if it does not.
