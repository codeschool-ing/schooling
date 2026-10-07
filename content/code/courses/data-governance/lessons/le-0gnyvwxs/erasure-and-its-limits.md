---
title: Erasure, and what the law keeps
version: 1
---

"Delete my data" sounds like one statement. In a company's database it is a decision per column,
because **article 16** allows keeping some data after its purpose ends, and other laws require it:

| | data may be kept for | at Ipê |
|---|---|---|
| I | **a legal or regulatory obligation** of the controller | orders and payments, for tax law; prescriptions of controlled medicines, for the health authority |
| II | **study by a research body**, anonymised where possible | — |
| III | **transfer to a third party**, if the law's requirements are met | — |
| IV | **the controller's exclusive use**, with no access by third parties, **and anonymised** | sales statistics, after lesson 5's techniques |

Article 18, VI gives the right to delete data **processed with consent**, "except in the cases of
article 16". Data processed under another basis ends when that basis does (article 15): the contract
is fulfilled, the period ends, the purpose is met. Either way, the answer to an erasure request is
rarely "all of it" and should never be "none of it".

## Customer 3

Customer 3 asked for deletion on 20 June. Before:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM health.prescriptions WHERE customer_id = 3) AS prescriptions, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"
SET
 orders | prescriptions | tickets 
--------+---------------+---------
      6 |             4 |       2
(1 row)
```

Six orders, four prescriptions, two support tickets. The decision, written as SQL so that it is
reviewed like code and runs as one transaction:

```sql
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
```

```
ana@lab:~/gov$ psql -f erase.sql
SET
BEGIN
INSERT 0 1
UPDATE 1
DELETE 2
UPDATE 1
UPDATE 1
COMMIT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, email, marketing_opt_in FROM sales.customers WHERE customer_id = 3" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"
SET
 customer_id |      email       | marketing_opt_in 
-------------+------------------+------------------
           3 | erased-3@invalid | f
(1 row)

 orders | tickets 
--------+---------
      6 |       0
(1 row)

ana@lab:~/gov$ psql service=davi -f due.sql
 request_id | customer_id |  kind   | received_on |   due_on   | state 
------------+-------------+---------+-------------+------------+-------
          3 |          47 | access  | 2026-06-10  | 2026-06-25 | LATE
          4 |          88 | correct | 2026-06-25  | 2026-07-10 | open
(2 rows)
```

What the transaction did, line by line:

- **marketing consent**: withdrawn as a new event, with the request as its channel. The event
  history stays, because it is the proof of what was consented to and when — section 6.
- **support tickets**: deleted. They served the relationship and no law requires them.
- **the e-mail**: replaced by an address that cannot receive mail. Nothing requires Ipê to keep it,
  and the customer row cannot simply go, because orders point at it.
- **orders, payments and prescriptions**: kept under article 16, I, and from now on usable only for
  the obligation that keeps them. Lesson 10 adds the date on which each of them goes.
- **the request**: answered, with the list of what went and what stayed and why.

The open requests now show two. The answer customer 3 receives says what was deleted and what was
kept under which rule — a person told "done" who later finds their orders in a tax audit has been
told something untrue.

## What `DELETE` does not reach

Three places the transaction above did not touch, and that a full answer accounts for:

- **backups**, which still hold customer 3's tickets until they expire. The usual and defensible
  practice is to let them expire on schedule, keep them out of normal use, and re-apply the deletion
  if one is ever restored;
- **copies elsewhere** — an analyst's extract, a CSV in an e-mail, a test database that lesson 6
  should have made synthetic;
- **other agents**: article 18, §6 requires telling anybody the data was shared with, and article
  16, III is not a licence to forget them.
