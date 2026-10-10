---
title: A customer who is no longer in the model
version: 1
---

The model can lose rows. A customer asks to be forgotten, and the shop erases them; a definition
changes, and the model sends only active customers. Either way, a contact that is in the CRM and no
longer in the model has to be dealt with, and **the right answer depends on why it left**.

Erasure is the case that has no choice. Brazil's data protection law, the LGPD, gives a person the right
to have their personal data deleted, and a copy in the CRM is their personal data as much as the row in
the shop's database. Erasing them from the source and leaving them in the CRM is an erasure that did
not happen.

Customer 2 asks to be forgotten, and the shop deletes them:

```
lantern=# DELETE FROM shop.customers WHERE customer_id = 2;
DELETE 1
ana@vm:~/reverse$ bash sync.sh
run 3: sent 0, removed 1, failed 0, retried after 429: 0
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-2'
[]
```

The sync's second loop found the contact that `last_sent` remembers and the model no longer has, and
sent `DELETE`. The CRM answers that it no longer holds anything with that key. And the log, in
`sync_log`, keeps the external id and the time of the deletion — which is what an auditor asking "when
did this person's data leave the CRM?" needs, and nothing about the person.

## When leaving the model is not erasure

If a contact leaves the model because a filter changed — the model sends only customers active in the
last year, and this one has gone quiet — deleting it from the CRM destroys the history salespeople wrote
on it: calls, notes, promises. Tools usually offer a choice for this case, and lesson 8 names the
options; the safe default is to **clear the synced fields** and leave the record, and to delete only
when the reason is that the customer must not be there at all.
