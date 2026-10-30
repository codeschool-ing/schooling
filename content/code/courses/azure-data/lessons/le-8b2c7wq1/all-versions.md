---
title: All versions and deletes
version: 1
---

**The second mode of the feed keeps every change, deletes included**: all versions and deletes. Each
entry carries the item as it became, the operation that made it, `create`, `replace` or `delete`, and its
position in the log. It is what an audit trail or a copy into another system needs, and it is the mode
where an order's `paid`, `packed` and `delivered` are three entries rather than one.

**It has to be switched on for the container, and it does not keep changes for ever.** On the emulator
the switch is a change feed policy with a retention period in minutes, set when the container is
created. On Azure the documentation ties the mode to continuous backup on the account, and keeps changes
only as long as that backup's retention, so a reader that falls further behind than that loses what
happened in between. A reader also cannot start this mode from the beginning, only from now or from a
saved token, as the Python library's own description of `query_items_change_feed` says, because there is no beginning to start from: the history exists only from when it was
switched on.

This part is practised. `versions.py` first asks the `orders` container of the earlier sections, which
has no policy, and then creates `orders-audited` with one, trying 60 minutes of retention before 10. It
takes a token at "now", and writes, changes and deletes one order. Save and run it:

`versions.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")

orders = db.get_container_client("orders")
try:
    list(orders.query_items_change_feed(mode="AllVersionsAndDeletes", start_time="Now"))
except Exception as e:
    print("orders:", e.message.splitlines()[0])

try:
    db.create_container_if_not_exists("orders-audited", PartitionKey("/customerId"),
                                      change_feed_policy={"retentionDuration": 60})
except Exception as e:
    print("60 minutes:", e.message.splitlines()[0])
audit = db.create_container_if_not_exists("orders-audited", PartitionKey("/customerId"),
                                          change_feed_policy={"retentionDuration": 10})
list(audit.query_items_change_feed(mode="AllVersionsAndDeletes", start_time="Now"))
token = audit.client_connection.last_response_headers["etag"]

audit.upsert_item({"id": "o-6", "customerId": "c-7", "status": "paid", "totalCents": 3100})
audit.upsert_item({"id": "o-6", "customerId": "c-7", "status": "packed", "totalCents": 3100})
audit.delete_item("o-6", partition_key="c-7")

for change in audit.query_items_change_feed(continuation=token):
    meta, now, before = change["metadata"], change.get("current"), change.get("previous")
    print(f"lsn {meta['lsn']}  {meta['operationType']:8} now: {now and now['status']}, before: {before and before['status']}")
```

```
ana@laptop:~/azure$ python versions.py
orders: (BadRequest) All versions and deletes requires an enabled changeFeedPolicy.
60 minutes: (BadRequest) 'changeFeedPolicy.retentionDuration' must be an integer from 1 through 10, or 0 to disable.
lsn 10  create   now: paid, before: None
lsn 11  replace  now: packed, before: paid
lsn 12  delete   now: None, before: packed
```

**The container without a policy refused the mode**, with a sentence that says exactly what is missing.
**The one with a policy returned three entries for one order**: the create, the replace from `paid` to
`packed`, and the delete, which carries no current item, only the one before it. That last entry is what
latest version can never give, and it is why a delete no longer needs the flag-and-time-to-live dance of
the earlier section when this mode is available.

**The retention period has a rule of the emulator's own**: asked for 60 minutes, it answered that
`retentionDuration` must be between 1 and 10, so `versions.py` asks again for 10. That limit is the emulator's.
On Azure the retention is the account's continuous backup period, and nothing in this course measured
it. The `previous` image on the replace is
also the emulator's answer; check on an account that your version of the service returns it before a
design relies on it.
