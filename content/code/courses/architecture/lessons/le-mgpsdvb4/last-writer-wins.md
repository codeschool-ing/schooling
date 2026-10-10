---
title: Last writer wins, and the write that disappears
version: 1
---

The stock has one owner, so its changes have one order. Some data has no single owner. A customer's
basket can be changed from a phone and a laptop at once, through two copies of the shop, and if each
copy accepts the change and tells the other afterwards, the two copies have each taken a write the
other did not see. Lesson 8 called this the AP corner: both sides keep answering, and the copies have
to be reconciled later.

The lab's shops do exactly that with baskets. Each one publishes the whole basket when it changes,
stamped with its own clock, and with `MERGE=lww` a shop keeps whichever basket was **changed last**. Ana
adds tea through shop `a`, and coffee through shop `b` a moment later:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee
shop-a: basket ana = tea
shop-b: basket ana = coffee
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = coffee
shop-b: basket ana = coffee
```

Both copies agree, and **the tea is gone**. No error, no log line saying a write was dropped: shop `a`
received a basket with a later timestamp and replaced its own. That is **last writer wins**, and it is
the default in more places than people expect: Cassandra resolves concurrent writes to a column this way,
and so do DynamoDB global tables, in their usual eventually consistent mode, across regions.

It is a fine rule when the later write really does replace the earlier one: a customer's delivery
address, the profile photo. It loses data whenever the two writes were **both meant**. And "last" is
decided by clocks on different machines, which drift apart; on two real servers, the change made second
can carry the earlier timestamp and lose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Ana&#x27;s basket in two shops at once. Shop a adds tea; shop b, a fraction of a second later, adds coffee. Each publishes its whole basket with a timestamp. Under last writer wins, both end with coffee only, because coffee&#x27;s timestamp is later, and the tea is gone without an error. Under union, both end with coffee and tea, but an item removed in one shop comes back the next time the other publishes.\"><defs><marker id=\"l9-lww-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop a: + tea  (10:00:00.1)</text><rect x=\"400\" y=\"30\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop b: + coffee  (10:00:00.3)</text><path d=\"M180 76 L180 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\"></path><path d=\"M540 76 L540 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\"></path><path d=\"M322 52 L398 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\" marker-start=\"url(#l9-lww-ah-wire)\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each publishes its whole basket</text><text x=\"40\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">last writer wins</text><rect x=\"40\" y=\"148\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a: coffee</text><rect x=\"400\" y=\"148\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">b: coffee</text><text x=\"40\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">union</text><rect x=\"40\" y=\"226\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a: coffee, tea</text><rect x=\"400\" y=\"226\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">b: coffee, tea</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tea lost</text></svg>", "caption": "Two writes that did not see each other. Last writer wins keeps one and drops the other; union keeps both and cannot tell a removal from an item the other side never had."}
```

## Keeping both

For a basket, the natural merge is to keep every item either copy has. That is `MERGE=union`:

```
ana@vm:~/lab/eventual$ MERGE=union CHECK_VERSION=1 docker compose up -d
 Container eventual-rabbitmq-1 Running 
 Container eventual-stock-1 Running 
 Container eventual-shop-a-1 Recreate 
 Container eventual-shop-b-1 Recreate 
 Container eventual-shop-b-1 Recreated 
 Container eventual-shop-a-1 Recreated 
 Container eventual-shop-b-1 Starting 
 Container eventual-shop-a-1 Starting 
 Container eventual-shop-b-1 Started 
 Container eventual-shop-a-1 Started 
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee
shop-a: basket ana = tea
shop-b: basket ana = coffee
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = coffee, tea
shop-b: basket ana = coffee, tea
```

Both writes survived. Now take the tea out through shop `a`, and add bread through shop `b` half a
second later, before `b` has heard about the removal:

```
ana@vm:~/lab/eventual$ curl -s -X DELETE localhost:8002/basket/ana/tea; sleep 0.5; curl -s -X PUT localhost:8003/basket/ana/bread
shop-a: basket ana = coffee
shop-b: basket ana = bread, coffee, tea
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = bread, coffee, tea
shop-b: basket ana = bread, coffee, tea
```

**The tea is back.** Shop `b` still had it when it published, and a union cannot tell "a removed it" from
"b never had it". This is the "item they removed reappears" from the table in lesson 8, and it is what
Amazon's own paper on Dynamo, in 2007, reported for its shopping cart: deleted items could resurface,
which they judged better than an item added and lost.

## The ways out

| approach | what it does | where it is used |
| --- | --- | --- |
| last writer wins | keeps one write, drops the rest | Cassandra, DynamoDB global tables; data where the newer value replaces the older |
| merge by union | keeps everything; removals can come back | Dynamo's shopping cart |
| keep both and ask | stores every concurrent version and hands them to the application to merge | Riak's "siblings"; the code that reads must be written for it |
| a CRDT | a data type whose merge is always right for its kind: a set that records removals with a tag, a counter per node | Riak data types, Redis Enterprise across regions, collaborative editors |
| one owner after all | route every change of one basket to one place | most shops; the simplest by far |

The last row is the honest answer for most systems. **Concurrent writes to the same thing are a cost you
choose to pay**, and the cheapest way to avoid paying it is to give each thing one owner, so its changes
have one order, and keep the copies for reading. Multi-writer designs earn their complexity where the
writers really cannot reach one place: several regions that must keep accepting writes when the link
between them fails, or devices that work offline.
