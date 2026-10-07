---
title: Rules that read an attribute
version: 1
---

Carla's policy already reads something that is not a role: the states she serves, from a table.
That is the idea of **attribute-based access control** — a rule that compares attributes of the
person, of the data and of the moment, rather than asking only which job somebody has. "An agent
sees tickets from customers in the states she serves." "A pharmacist sees a prescription only
while the order is open." "Nobody exports health data outside office hours."

The power of it is that one rule covers every case its attributes describe. The danger is in a
question nobody asks about the attributes themselves: **who sets them?**

## A first draft, and why it is wrong

The tickets table needs the same rule as the customers. Ana's first draft takes the region from a
**setting of the session**, which is quick to write and tempting, because many applications
already set one:

```sql
-- A FIRST DRAFT, AND WRONG: the region comes from a setting of the session.
SET ROLE ipe_owner;
CREATE POLICY agent_sees_session_region ON support.tickets
  FOR SELECT TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c
                         WHERE c.state = current_setting('ipe.region', true)));
ALTER TABLE support.tickets ENABLE ROW LEVEL SECURITY;
```

```
ana@lab:~/gov$ psql -f setting.sql
SET
CREATE POLICY
ALTER TABLE
ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'SP'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
   586
(1 row)

ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'MG'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
     0
(1 row)
```

It filters exactly as intended. Carla says she is working on São Paulo and sees 586 tickets.

And then the problem: **Carla chose the value.** Anybody can `SET` a custom setting in their own
session — that is what custom settings are for — so the "attribute" deciding what she may see is
one she can change by typing a different state. Here it happened to narrow her view. A rule
written the other way round, or a setting naming a level of clearance, would widen it.

**An attribute that decides access has to come from somewhere the person cannot write.** The
session's settings, a header the client sends, a field in a form, a claim in a token the
application did not verify — each one is the user describing themselves.

## The attribute from a table

```sql
-- The attribute comes from a table Carla can read and cannot write.
SET ROLE ipe_owner;
DROP POLICY agent_sees_session_region ON support.tickets;
CREATE POLICY agent_sees_own_states ON support.tickets
  FOR ALL TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c))
  WITH CHECK (status IN ('open', 'closed'));
```

```
ana@lab:~/gov$ psql -f attribute.sql
SET
DROP POLICY
CREATE POLICY
ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'MG'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
   854
(1 row)

ana@lab:~/gov$ psql service=carla -c "INSERT INTO support.agent_regions VALUES ('carla', 'MG')"
ERROR:  permission denied for table agent_regions
ana@lab:~/gov$ psql service=carla -c "UPDATE support.tickets SET status = 'escalated' WHERE ticket_id = 2"
ERROR:  new row violates row-level security policy for table "tickets"
ana@lab:~/gov$ psql service=carla -c "UPDATE support.tickets SET status = 'closed' WHERE ticket_id = 2"
UPDATE 1
```

The tickets policy no longer reads any setting. It allows a ticket when its customer is one Carla
can see — and which customers she can see is already decided by the policy on
`sales.customers`, which reads `support.agent_regions`. **A policy's subquery runs under the
reader's own privileges and policies**, so one rule about regions now governs both tables.

What Carla tries next is refused for the right reasons:

- **Setting `ipe.region` to `MG` changes nothing.** She sees 854 tickets: São Paulo's and Rio's.
- **Adding herself to Minas Gerais is refused**, because the attribute table is readable by
  agents and writable only by its owner.
- **An update has to leave the row inside the policy.** The `WITH CHECK` clause allows a status
  of `open` or `closed` and nothing else, so `escalated` is refused and `closed` is accepted.

That last line is a different use of the same machinery. `USING` decides which existing rows a
role may see, update or delete; `WITH CHECK` decides which rows it may *write*. A support agent
who could set any status could invent states the rest of the system does not understand.

## Where attributes live in practice

In a warehouse or a lakehouse the attributes are tags: a column tagged `pii`, a dataset tagged
`health`, a person whose group membership in the identity provider says `region:south`. The
platform evaluates rules over the tags. The question is the same and so is the answer: **the
tags on the data are set by whoever governs the data, and the attributes of a person by whoever
governs identity** — never by the person the rule is about.
