---
title: Free text
version: 1
---

Every column so far has a type and a meaning. One does not. `support.tickets.body` is whatever a
customer typed into a form, and customers type what they think will help:

```sql
-- What customers typed into the support form, counted by what it contains.
SET ROLE ipe_owner;
SELECT count(*) AS tickets,
       count(*) FILTER (WHERE body ~ '\d{3}\.\d{3}\.\d{3}-\d{2}') AS with_a_cpf,
       count(*) FILTER (WHERE body ~ '[[:alnum:]._]+@[[:alnum:].]+') AS with_an_email,
       count(*) FILTER (WHERE body ~* 'sertraline|insulin|clonazepam') AS naming_a_medicine
FROM support.tickets;
```

```
ana@lab:~/gov$ psql -f tickets.sql
SET
 tickets | with_a_cpf | with_an_email | naming_a_medicine 
---------+------------+---------------+-------------------
    1500 |         82 |            55 |                26
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT ticket_id, body FROM support.tickets WHERE body ~* 'sertraline' ORDER BY ticket_id LIMIT 2"
SET
 ticket_id |                                      body                                       
-----------+---------------------------------------------------------------------------------
        20 | Please stop sending me promotions. I take sertraline and need it before Friday.
        60 | Please stop sending me promotions. I take sertraline and need it before Friday.
(2 rows)
```

Of 1,500 tickets, 82 contain something shaped like a CPF, 55 an e-mail address and 26 the name of a
medicine. Two of them:

The customer asking Ipê to stop sending promotions also wrote down that they take sertraline. **A
free-text column holds whatever its writers chose to put in it**, so its class is the most sensitive
thing anybody might have typed — which is why section 7 classified `body` as `sensitive`, though the
form was designed for delivery complaints.

The patterns found here are the easy ones: digits in a CPF's shape, an `@`. A sentence that says "my
son's epilepsy medicine" has no pattern, and no regular expression finds every way a person can
describe their health. Counting what the patterns catch gives a floor, never the whole.

## What to do about it

**Redact what other people read.** Support needs the ticket as written. Analysts studying why
customers write in do not need anybody's CPF or medicine:

```sql
-- What analysts may read of a ticket: the text with the patterns that
-- identify somebody, or reveal their health, replaced.
SET ROLE ipe_owner;
CREATE VIEW support.tickets_redacted AS
SELECT ticket_id, opened_at, status,
       regexp_replace(
         regexp_replace(
           regexp_replace(body, '\d{3}\.\d{3}\.\d{3}-\d{2}', '[CPF]', 'g'),
           '[[:alnum:]._]+@[[:alnum:].]+', '[EMAIL]', 'g'),
         'I take [a-z]+', 'I take [MEDICINE]', 'gi') AS body
FROM support.tickets;
GRANT USAGE ON SCHEMA support TO analyst;
GRANT SELECT ON support.tickets_redacted TO analyst;
```

```
ana@lab:~/gov$ psql -f redact.sql
SET
CREATE VIEW
GRANT
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT ticket_id, body FROM support.tickets_redacted WHERE position('[' IN body) > 0 ORDER BY ticket_id LIMIT 4"
 ticket_id |                                      body                                       
-----------+---------------------------------------------------------------------------------
         2 | My order has not arrived yet. My CPF is [CPF].
         9 | How do I change my delivery address? Write to me at [EMAIL] please.
        20 | Please stop sending me promotions. I take [MEDICINE] and need it before Friday.
        21 | I want to cancel my order. My CPF is [CPF].
(4 rows)
```

The view replaces the three patterns and nothing else; the topic of each ticket survives. It is a
default view, running as its owner, so analysts read redacted text and never the table. A ticket
whose medicine was spelt in a way the pattern does not know will still show it, which is why the
grant is to analysts and not to the world.

**Ask less of the form.** A field labelled "describe your problem" invites everything; a choice of
reasons plus an order number covers most tickets and invites nothing. Minimisation (section 11)
begins at the form.

**Treat free text in logs the same way.** An application that logs request bodies, a pipeline that
dumps a failing row into an error message, a chat transcript kept "for quality" — each is a
free-text column by another name, and usually less protected than this one.
