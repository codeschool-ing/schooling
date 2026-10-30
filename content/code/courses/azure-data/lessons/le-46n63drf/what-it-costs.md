---
title: What each level costs, in units, waiting and regions
version: 1
---

**A stronger level is not a slower version of a weaker one; it is a different amount of work per
request**, and Cosmos DB charges for it in three currencies: request units, latency and the regions
an account is allowed to have. This section is taught from Microsoft's documentation and was not
run, because the emulator charges one request unit for everything and has one copy and no regions.

## Request units: reads at the top two levels cost about twice

**A request unit is the currency Cosmos DB bills its work in**, and lesson 13 is about it. Here only
one fact matters: Microsoft's documentation puts the request units of a read at strong or bounded
staleness at roughly twice those of the same read at session, consistent prefix or eventual. The
reason is the copies. A read at the two strong levels is answered by two replicas that have to
agree, a minority quorum, and the other three levels are answered by one. **Writes cost the same at
every level**, because every write is committed to a majority of the copies whatever the level is.

Put a number on it. Quitanda's product page reads one product document of about 1 KB, and at the
evening peak it is asked for 3,000 times a second. Lesson 13 shows that a point read of 1 KB costs
one request unit:

| level | request units a second, for the page alone |
|---|---|
| session, consistent prefix, eventual | 3,000 |
| strong, bounded staleness | about 6,000 |

**Throughput is reserved and billed per request unit a second**, so the second row is roughly twice
the bill for the same page, every hour the reservation exists. A catalogue that changes a few times a
day buys nothing with those 3,000 extra units.

## Latency: strong waits for the farthest region

Within one region, Microsoft's service level agreement promises reads and writes under 10
milliseconds at the 99th percentile, at every level. **Across regions, strong changes the writes.**
A write at strong is acknowledged only once every region has it, so its latency includes the round
trip to the farthest region: the documentation gives twice that round trip plus 10 milliseconds, at
the 99th percentile. Between São Paulo and a region in the United States, that is a wait on every
write that no index or partition key can remove. Bounded staleness, session, consistent prefix and
eventual commit in the local region and replicate afterwards.

## Regions: strong and many writers do not mix

An account can accept writes in one region or in all of them. **With writes in several regions,
strong is not offered**, because two regions accepting writes at once cannot both see the latest
value without waiting for each other, which is the latency above, on every write, in both
directions. Writes in several regions also bring conflicts: two regions change the same order in the
same second, and Cosmos DB keeps one version by a policy you choose, by default the one with the
later timestamp.

## What a regional outage can lose

The level also decides how much a failover may lose when a whole region goes down with writes that
had not crossed yet. For an account with one write region, Microsoft's documentation gives:

| level | writes that may be lost when the write region is lost |
|---|---|
| strong | none |
| bounded staleness | at most the K writes or T seconds of the bound |
| session, consistent prefix, eventual | up to about 15 minutes |

This is the same shape as the geo-redundant storage of lesson 1, and for the same reason:
replication across regions is asynchronous unless something waits for it, and strong is the level
that waits.

## Quitanda's choice

| data | level | why |
|---|---|---|
| orders | session | the customer must see their own payment; nobody else needs it that instant |
| product catalogue | eventual, asked for by the page's client | changes rarely, read constantly, a second of age is harmless |
| stock to reserve | session, with a conditional write | the level cannot stop two buyers taking the last item |

**The last row is the one people get wrong.** Strong consistency does not make *read, subtract one,
write* safe: two clients can both read 1 at strong, both write 0, and two customers have bought the
last bunch of coriander. What makes it safe is the conditional write lesson 2 used on a blob: write
only if the item's ETag is still the one you read, and try again if it is not. That works at every
level, costs nothing extra, and is the same idea as the session token: a promise kept by carrying a
string back to the server.

The account itself stays at session, in `brazilsouth` only, so that the data stays in Brazil and
nothing pays the round trip to another country.
