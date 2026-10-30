---
title: Latest version only, and the delete that is an update
version: 1
---

**The default mode of the feed is called latest version, and the name is exact: it shows each item as
it is now, once.** `o-1` was written three times and appeared once, as `delivered`. A reader that wanted
to know when it was packed has no way to find out, because the feed is not a log of every write; it is
the container's items, ordered by when they last changed. Two things follow, and every design on top of
the feed has to accept them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"Six writes in order, lsn 1 to 6: o-1 paid, o-2 paid, o-3 paid, o-1 packed, o-1 delivered, and o-2 deleted. The latest version feed shows two entries: o-3 paid at lsn 3 and o-1 delivered at lsn 5; the two earlier states of o-1 and everything about o-2 are absent. The all versions and deletes feed shows all six, including the delete.\" data-fig=\"l14-modes\"><text x=\"220\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 1</text><text x=\"302\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 2</text><text x=\"384\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 3</text><text x=\"466\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 4</text><text x=\"548\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 5</text><text x=\"630\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 6</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">written, in order</text><rect x=\"184\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"220\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"266\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"302\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"302\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"348\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"430\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"466\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"466\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packed</text><rect x=\"512\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">delivered</text><rect x=\"594\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"630\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">delete</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">latest version</text><rect x=\"184\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"266\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"348\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">paid</text><rect x=\"430\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"512\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">delivered</text><rect x=\"594\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">all versions and deletes</text><rect x=\"184\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"220\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"220\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"266\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"302\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"302\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"348\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"430\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"466\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"466\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">packed</text><rect x=\"512\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">delivered</text><rect x=\"594\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"630\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"630\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">delete</text><text x=\"370\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Latest version keeps one entry per living item; the other mode keeps every step, for its retention period.</text></svg>", "caption": "The six writes feed.py made, and what each mode of the feed returns for them. The first two rows are what feed.py printed."}
```

**Intermediate states can be missed.** A reader that polls every minute sees an order that was paid,
packed and delivered inside that minute as delivered. Nothing is lost that the item still says, and
everything it no longer says is gone. If the steps matter, they belong in the item, a list of status
changes with their times, or in the other mode of the next section but one.

**Deletes are not in the feed at all.** `o-2` was created and deleted, and no entry says so. A view
built from the feed keeps a deleted order for ever, because nothing told it to remove the order. The
usual answer is to delete in two steps: **first an update that marks the item deleted**, which the feed
carries like any other change, **and a time to live that removes the item later**, after every reader
has had time to see the mark.

`feed.py` created the container with `default_ttl=-1`, which switches time to live on for the container
without giving any item one; an item then expires only if it carries its own `ttl`, in seconds. Save
this as `softdelete.py`. It marks `o-3` cancelled and deleted with a `ttl` of 5, reads the feed from
where it stood, and checks eight seconds later:

`softdelete.py`:

```python
import time

from azure.cosmos import CosmosClient, exceptions

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
orders = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda").get_container_client("orders")

list(orders.query_items_change_feed(start_time="Beginning"))
token = orders.client_connection.last_response_headers["etag"]

order = orders.read_item("o-3", partition_key="c-7")
order.update({"status": "cancelled", "deleted": True, "ttl": 5})
orders.upsert_item(order)
for change in orders.query_items_change_feed(continuation=token):
    print("the feed shows:", change["id"], change["status"], "deleted =", change["deleted"], "ttl =", change["ttl"])

time.sleep(8)
try:
    orders.read_item("o-3", partition_key="c-7")
except exceptions.CosmosResourceNotFoundError:
    print("eight seconds later o-3 is gone, removed by its time to live")
```

```
ana@laptop:~/azure$ python softdelete.py
the feed shows: o-3 cancelled deleted = True ttl = 5
eight seconds later o-3 is gone, removed by its time to live
```

**The feed carried the mark, and the time to live did the deleting.** A reader of the feed saw `o-3`
with `deleted = True` and could remove it from whatever it builds; eight seconds later the item was gone
from the container, and with it from the feed. The emulator enforced the time to live. On Azure the
deletion is done in the background, with request units the container is not using for anything else.

**The `ttl` is a promise to the readers, and it must be longer than the slowest of them.** Five seconds
is a number for a lesson. A processor that runs every night needs a day at the very least, and one that
may be down for a weekend needs the weekend. If the item expires before a reader has seen the mark, that
reader never learns about the delete, which is the problem the mark was meant to solve.
