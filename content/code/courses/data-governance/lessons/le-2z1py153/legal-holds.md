---
title: The exception — legal holds
version: 1
---

Customer 4407 is suing Ipê over a refund on an order from 2020. That order is past its retention
period. If the purge deleted it next week, Ipê would be destroying evidence in a case it is part of,
which no retention rule can justify. The LGPD itself allows keeping data for the **regular exercise of
rights in judicial, administrative or arbitration proceedings** (article 7, VI), and deleting the
records of a dispute while it is in court would be indefensible in that court.

A **legal hold** suspends the purge for the data it covers, for as long as the case lasts:

```sql
-- Customer 4407 is in court over a refund from 2020. Nothing of theirs is
-- deleted until the case ends, whatever the retention rule says.
SET ROLE ipe_owner;
CREATE TABLE gov.legal_holds (
  customer_id integer NOT NULL,
  reason      text    NOT NULL,
  since       date    NOT NULL,
  released_on date
);
INSERT INTO gov.column_class VALUES
 ('gov','legal_holds','customer_id','personal','whose data is held'),
 ('gov','legal_holds','reason','personal','a dispute about a person'),
 ('gov','legal_holds','since','personal','when it began'),
 ('gov','legal_holds','released_on','personal','when it ended');
INSERT INTO gov.legal_holds VALUES
 (4407, 'lawsuit over the refund of order 105213, filed 2026-03-02', '2026-03-09', NULL);
```

Three properties make a hold work:

- **it is data, not a conversation.** A lawyer telling the database team "don't delete anything about
  4407" by e-mail is a hold that lasts until the e-mail is forgotten. A row is read by the purge every
  time it runs;
- **it has a start and an end.** `released_on` is filled in when the case closes, and from the next run
  on, the retention rules apply again. A hold nobody releases is indefinite retention by another name;
- **it is personal data itself**, about a person in a dispute, and classified as such in the same
  migration.

## What the hold covers

Here, everything about one customer: their old orders, prescriptions and tickets. Holds can be
narrower — one order — or wider — every record of a product line under investigation by the health
authority. The shape of the table follows what the holds need to name; the rule that the purge reads
it does not change.
