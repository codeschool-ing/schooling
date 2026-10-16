---
title: The key that recognises a customer
version: 1
---

The sync sends `PUT /contacts/lantern-1500`, and the CRM updates the record with that key or creates
it. That pattern is called an **upsert**, and it depends entirely on both sides agreeing on the key.
What happens without one is easy to show. Many CRM integrations are written with `POST`, which means
"create a contact", and run more than once — after a failure, or because two people scheduled the
same job. Save this as `post-twice.sh` and run it:

```sh
curl -s -X POST localhost:8000/contacts -H 'Content-Type: application/json' \
  -d '{"external_id": "lantern-10", "segment": "home", "health": "lapsed"}'; echo
curl -s -X POST localhost:8000/contacts -H 'Content-Type: application/json' \
  -d '{"external_id": "lantern-10", "segment": "home", "health": "lapsed"}'; echo
```

```
ana@vm:~/reverse$ bash post-twice.sh
{"status": "created", "crm_id": 2650}
{"status": "created", "crm_id": 2651}
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-10'
[{"external_id": "lantern-10", "segment": "home", "region": "South", "orders": 1, "net_revenue": 41.31, "last_order": "2025-06-11", "health": "lapsed", "crm_id": 1}, {"external_id": "lantern-10", "segment": "home", "health": "lapsed", "crm_id": 2650}, {"external_id": "lantern-10", "segment": "home", "health": "lapsed", "crm_id": 2651}]
```

Both requests succeeded, and the `curl` after the script asks the CRM what it holds for that key:
three records for one customer, the one the sync made with `PUT` and two copies made with `POST`. Each will be shown to a salesperson, each can be edited separately, and a report of contacts counts the
customer three times. **Duplicates are the defining failure of syncs into operational tools**, and the
CRM did nothing wrong: `POST` means create, so it created.

## Which key

The match key has to be something that identifies the customer, never changes, and exists on both
sides:

| candidate | problem |
|---|---|
| the CRM's own id (`crm_id`) | the shop does not know it until the CRM has created the record |
| the e-mail address | people change it, share it, and type it with capitals; two records for one person, or one for two |
| the shop's customer id (`lantern-1500`) | none of those: it is assigned once, by the system that owns the customer |

Most CRMs let you add a custom field marked as an **external id**, unique and indexed, precisely so an
upsert can match on it. The sync uses the shop's id as that field from the first request, and so never
needs to know the CRM's number at all.
