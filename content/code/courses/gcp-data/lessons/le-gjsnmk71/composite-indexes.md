---
title: Composite indexes, and where the emulator is weaker
version: 1
---

**A query that filters or sorts on two fields needs an index that holds both, in that order, and
Firestore does not build those by itself.** A **composite index** is declared: a collection or a
collection group, a list of fields, each ascending or descending. `pending-biggest` needs `status`
then `total_cents` descending, so that all the pending orders sit together in the index already
sorted by total, and the query reads the first five entries of that stretch and stops. No single-field
index has that shape, because the one on `status` is sorted by `status` alone and the one on
`total_cents` mixes every status together.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two indexes over the same orders. On the left, the single-field index on status: the four pending entries are together, but their totals are in no order, 4287, 14730, 9960, 13410, so finding the biggest means reading all of them and sorting. On the right, the composite index on status then total_cents descending: the pending entries are together and already sorted, 14730, 13410, 9960, 4287, so the query reads the first entries of that stretch and stops.\" data-fig=\"l10-composite\"><defs><marker id=\"ah-l10-composite\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">single-field index</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">status</text><rect x=\"30\" y=\"56\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cancelled</text><text x=\"318\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12030</text><rect x=\"30\" y=\"86\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"318\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6149</text><rect x=\"30\" y=\"116\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"318\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20040</text><rect x=\"30\" y=\"146\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4287</text><rect x=\"30\" y=\"176\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14730</text><rect x=\"30\" y=\"206\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9960</text><rect x=\"30\" y=\"236\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13410</text><text x=\"30\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pending together, totals unsorted</text><text x=\"30\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the biggest needs every entry read</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">composite index</text><text x=\"390\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">status, total_cents desc</text><rect x=\"390\" y=\"56\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cancelled</text><text x=\"678\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12030</text><rect x=\"390\" y=\"86\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"678\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20040</text><rect x=\"390\" y=\"116\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"678\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6149</text><rect x=\"390\" y=\"146\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14730</text><rect x=\"390\" y=\"176\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13410</text><rect x=\"390\" y=\"206\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9960</text><rect x=\"390\" y=\"236\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4287</text><text x=\"390\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pending together, biggest first</text><text x=\"390\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the query reads the top and stops</text></svg>", "caption": "The same pending orders in two indexes. Only the composite one holds them in the order pending-biggest asks for."}
```

**The wrong idea is that Firestore picks the best index it has.** It uses an index that fits the query
exactly, or it refuses. Google Cloud's refusal is a `FAILED_PRECONDITION` whose message says the query
requires an index and includes a link to the console with the index already filled in. That is the
experience every Firestore developer has on their first real query, and it is the one the emulator
does not give.

## The emulator answers anyway

```
ana@laptop:~/gcp$ python3 query.py pending-biggest
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
customers/c-31/orders/o-10033    2026-10-14 pending    13410 eggs-12,rice-5kg,coffee-500g
customers/c-23/orders/o-10014    2026-10-09 pending    12449 eggs-12,tomato,rice-5kg
customers/c-33/orders/o-10043    2026-10-17 pending    10168 rice-5kg,tomato
customers/c-26/orders/o-10020    2026-10-07 pending     9960 rice-5kg,eggs-12
ana@laptop:~/gcp$ python3 query.py lapa-late-october
customers/c-34/orders/o-10045    2026-10-21 delivered   9750 banana,rice-5kg
customers/c-22/orders/o-10011    2026-10-24 cancelled  12030 rice-5kg,banana,eggs-12
customers/c-26/orders/o-10021    2026-10-25 cancelled   7557 banana,tomato,rice-5kg
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
```

**Both queries answered, with no composite index anywhere.** The emulator in its default mode, Native,
checks no index at all: it answers whatever it is asked, with a plan of its own that Google Cloud would
not run. A program tested only against it can ship with a query that fails on its first call in
production, and nothing on the laptop would have warned you. **This is the place where the emulator is
weaker than Firestore**, and the habit that follows from it is to keep the composite indexes in a file
from the first day, deployed with the code, rather than to wait for the error.

**The emulator cannot tell you what a query read, either.** Firestore's **Query Explain** returns the
plan and, with `analyze`, the documents and index entries read and the read operations billed:

`explain.py`:

```python
#!/usr/bin/env python3
"""Ask Firestore what it read to answer a query: Query Explain."""
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.query_profile import ExplainOptions, QueryExplainError

db = firestore.Client(project='planner-dev')
query = db.collection_group('orders').where(filter=FieldFilter('status', '==', 'pending'))
try:
    results = query.get(explain_options=ExplainOptions(analyze=True))
    print(len(results), 'documents')
    print(results.get_explain_metrics())
except QueryExplainError as missing:
    print('no explain metrics:', missing)
```

```
ana@laptop:~/gcp$ python3 explain.py
no explain metrics: explain_metrics not available until query is complete.
```

**The emulator returned no metrics**, because it does not produce them. On Google Cloud the same
program prints the index used and the counts; the pricing page itself names Query Explain as the way
to confirm whether a query is charged for index entries read.

## Declaring the index, not run

**On Google Cloud the index for `pending-biggest` is one command**, and it is shown here as you would
type it. **It was not run**: the index commands go to Google's Firestore admin service, which has no
emulator, and no output is shown.

```sh
gcloud firestore indexes composite create --collection-group=orders --query-scope=collection-group \
  --field-config=field-path=status,order=ascending \
  --field-config=field-path=total_cents,order=descending
```

**`--query-scope=collection-group` matters here**, because the query reads every `orders` collection
under every customer; the same index with the default scope, `collection`, would serve a query on one
customer's orders and not this one. An index takes time to build on existing documents, and while it
builds the query still fails. Firestore documents a limit on the number of composite indexes per
database, which is a reason to design the queries before the indexes rather than to add one per
screen.

**Every composite index is paid for on every write.** A new order is one document, and it becomes one
entry in each single-field index of each of its fields and one entry in every composite index whose
fields it has. Those entries are storage, billed with the documents, and work the write has to do
before it is acknowledged. A collection with a dozen composite indexes writes a dozen extra entries per
document, which is the reason to keep the list to the queries the app actually runs.

## Datastore mode, which can be made strict

**The same emulator has a second mode that does check indexes**, and it is the closest the laptop gets
to the real refusal. Datastore mode is the subject of the last section; what matters here is two flags,
`--require-indexes` and `--index-file`, which the emulator's help says work only in that mode. The index
file is Datastore's format.

`index.yaml`:

```yaml
indexes:
- kind: Order
  properties:
  - name: status
  - name: total_cents
    direction: desc
```

In a third terminal, on a port of its own:

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators firestore start --database-mode=datastore-mode --require-indexes --index-file=index.yaml --host-port=localhost:8081
```

**A Datastore-mode database is read with a different client library**, `google-cloud-datastore`, which
is not in lesson 1's list, and it finds the emulator through `DATASTORE_EMULATOR_HOST`:

```sh
pip install -q google-cloud-datastore==2.27.0
```

`ds.py`:

```python
#!/usr/bin/env python3
"""The same orders as entities of kind Order, in a database in Datastore mode."""
from google.api_core.exceptions import FailedPrecondition
from google.cloud import datastore
from google.cloud.datastore.query import PropertyFilter

client = datastore.Client(project='planner-dev')
for n, (status, cents, day) in enumerate([('pending', 4287, '2026-10-10'), ('delivered', 6149, '2026-10-06'),
                                          ('pending', 12449, '2026-10-09'), ('pending', 9960, '2026-10-07')]):
    order = datastore.Entity(client.key('Order', f'o-{10001 + n}'))
    order.update({'status': status, 'total_cents': cents, 'day': day})
    client.put(order)

for sort in ('-total_cents', 'day'):
    query = client.query(kind='Order', filters=[PropertyFilter('status', '=', 'pending')], order=[sort])
    try:
        print(f'pending, by {sort:<13}', [order.key.name for order in query.fetch()])
    except FailedPrecondition as refused:
        print(f'pending, by {sort:<13}', 'refused:', refused.message)
```

```
ana@laptop:~/gcp$ DATASTORE_EMULATOR_HOST=localhost:8081 python3 ds.py
pending, by -total_cents  ['o-10003', 'o-10004', 'o-10001']
pending, by day           refused: The query requires a composite index that is not defined in your indexes file.
```

**The query the file declares an index for answered, and the one it does not was refused**, with a
sentence that says so. Datastore calls a document an **entity** and a collection a **kind**, and the
two queries are `pending-biggest` again, then the pending orders by day, which needs `status` then
`day`, an index nobody declared. That refusal is what Google Cloud does in both modes, and it is the
behaviour to expect from the real service, whichever mode the laptop was in.
