---
title: A processor that keeps its place in a blob
version: 1
---

**A program that reads the feed once is a script; one that reads it forever, picking up where it
stopped, is a processor**, and the whole difference is where it keeps its place. The continuation
token of the first section is that place. A processor saves it after each batch, and the next run, on
this machine or another, starts from it. This section builds the smallest one that is correct: it
turns Quitanda's orders into what each customer has spent, and keeps both the view and its token as
blobs in Azurite. It needs the Cosmos DB emulator and Azurite, started together:

```sh
docker compose --profile cosmos up -d
```

Save it as `processor.py`:

```schooling-example
{"language": "python", "file": "processor.py", "parts": [
{"code": "import json\nimport os\n\nfrom azure.core.exceptions import ResourceNotFoundError\nfrom azure.cosmos import CosmosClient\nfrom azure.storage.blob import BlobServiceClient\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\norders = CosmosClient(\"http://localhost:8081\", KEY).get_database_client(\"quitanda\").get_container_client(\"orders\")\nstate = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\nstate = state.get_container_client(\"processor\")\nif not state.exists():\n    state.create_container()\n", "note": "Two clients: the orders container in Cosmos DB, and a blob container in Azurite called `processor` that holds the processor's state. The storage connection string is the one every terminal of this course exports."},
{"code": "\n\ndef load(name, default):\n    try:\n        return state.download_blob(name).readall().decode()\n    except ResourceNotFoundError:\n        return default\n", "note": "`load` reads a blob as text, or answers a default when the blob does not exist yet, which is the first run."},
{"code": "\n\nspend = json.loads(load(\"spend.json\", \"{}\"))\ntoken = load(\"checkpoint\", None)\nif token:\n    changes = orders.query_items_change_feed(continuation=token)\nelse:\n    changes = orders.query_items_change_feed(start_time=\"Beginning\")\n", "note": "The state is two blobs: `spend.json`, the view being built, and `checkpoint`, the continuation token of the last run. With a token, the feed resumes after it; without one, it starts from the beginning."},
{"code": "\napplied = 0\nfor change in changes:\n    mine = spend.setdefault(change[\"customerId\"], {})\n    if change.get(\"deleted\"):\n        mine.pop(change[\"id\"], None)\n    else:\n        mine[change[\"id\"]] = change[\"totalCents\"]\n    applied += 1\n", "note": "The view is keyed by order id inside each customer. **Applying a change sets a value, it does not add one**, so applying the same change twice leaves the same view. An order flagged deleted is removed."},
{"code": "\nstate.upload_blob(\"spend.json\", json.dumps(spend, sort_keys=True), overwrite=True)\nif os.environ.get(\"CRASH\") == \"before-checkpoint\":\n    raise SystemExit(f\"applied {applied} and stopped before the checkpoint\")\nstate.upload_blob(\"checkpoint\", orders.client_connection.last_response_headers[\"etag\"], overwrite=True)\n", "note": "The view is saved first and the token second. Between the two is where a crash puts the processor; `CRASH=before-checkpoint` stops it exactly there, to see what happens next."},
{"code": "\nprint(f\"applied {applied} changes\")\nfor customer, by_order in sorted(spend.items()):\n    print(f\"  {customer}  {len(by_order)} orders  {sum(by_order.values()) / 100:8.2f}\")\n", "note": "What it applied, and the view."}
]}
```

And a one-line way to place an order, saved as `order.py`:

`order.py`:

```python
import sys

from azure.cosmos import CosmosClient

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
orders = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda").get_container_client("orders")
order_id, customer, cents = sys.argv[1], sys.argv[2], int(sys.argv[3])
orders.upsert_item({"id": order_id, "customerId": customer, "status": "paid", "totalCents": cents})
```

```
ana@laptop:~/azure$ python processor.py
applied 3 changes
  c-7  1 orders     48.90
  c-9  1 orders     21.00
ana@laptop:~/azure$ python processor.py
applied 0 changes
  c-7  1 orders     48.90
  c-9  1 orders     21.00
ana@laptop:~/azure$ python order.py o-5 c-8 990 && CRASH=before-checkpoint python processor.py
applied 1 and stopped before the checkpoint
ana@laptop:~/azure$ python processor.py
applied 1 changes
  c-7  1 orders     48.90
  c-8  1 orders      9.90
  c-9  1 orders     21.00
```

**The first run applied three changes**: `o-1`, `o-4`, and `o-3`. The emulator still listed `o-3`'s
last version, flagged deleted, after its time to live had removed it; the processor saw the flag and left
it out of the view, which is why `c-7` has one order. Whether Azure still lists an expired item's last
version is not something this course could check, and the design should not depend on it: the time to
live is set long enough that every reader sees the flag first. **The second run applied nothing**,
because the token said where the first had stopped.

**Then the crash.** A new order for `c-8` was placed, and the processor applied it, saved the view and
stopped before saving the token. The next run started from the old token, read `o-5` again and applied
it again, and `c-8` shows 9.90 and not 19.80:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"The processor's loop in four steps: read the feed from the checkpoint, apply the changes by setting values, save the view to spend.json, save the token to checkpoint. An amber break between saving the view and saving the token marks where CRASH=before-checkpoint stops it. A dashed arrow returns from the end to the start: the next run starts from the last saved token, so a crash at the break re-reads changes already in the view.\" data-fig=\"l14-loop\"><defs><marker id=\"l14-p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--phosphor)\"/></marker><marker id=\"l14-w-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">read the feed</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from checkpoint</text><line x1=\"162\" y1=\"78\" x2=\"193\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"195\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"265\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">apply the changes</text><text x=\"265\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set, never add</text><line x1=\"337\" y1=\"78\" x2=\"368\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"370\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"440\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">save the view</text><text x=\"440\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">spend.json</text><line x1=\"512\" y1=\"78\" x2=\"543\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"545\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"615\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">save the token</text><text x=\"615\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checkpoint</text><path d=\"M528,30 L534,40 L522,48 L534,58 L522,68 L534,78 L522,88 L534,98 L522,108 L528,120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"528\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">CRASH=before-checkpoint</text><path d=\"M650,108 C650,190 90,190 90,110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-w-ah)\"/><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the next run starts from the last saved token</text><text x=\"370\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A crash at the amber line re-reads changes already in the view. Setting values makes that harmless; adding them would count twice.</text></svg>", "caption": "Work first, checkpoint second: the order that loses nothing and repeats something."}
```

**Saving the view first and the token second is the only order that loses nothing**: the other way
round, a crash between the two would record a position past changes that never reached the view, and
they would never be read again. The price of the safe order is that some changes are read twice, which
is called at-least-once delivery. The processor survives it because each change sets `spend[c-8][o-5]`
to 990 rather than adding 990 to a total, so doing it twice is the same as doing it once. Lesson 24 is
about that property, idempotence, and every consumer of a feed or a stream needs it.

Two things this processor does not do, and a real one has to. It handles one copy of itself: two
processes started together would both read from the same token and overwrite each other's view. And it
reads the whole feed as one range, where a container with many physical partitions can be read in
parallel, range by range. Both are what the change feed processor of the last section is for.
