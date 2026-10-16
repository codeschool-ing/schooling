---
title: The eviction policies, under the same load
version: 1
---

A policy other than `noeviction` makes Redis delete keys to make room, and the policy says which.
The names are two choices joined by a dash: **which keys may be evicted, and how one is picked
among them.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A grid of the eviction policies. The columns are how a key is picked: least recently used, least frequently used, closest to expiring, and at random. The rows are which keys may be evicted: all keys, or only keys with an expiry. The all-keys row holds allkeys-lru, allkeys-lfu and allkeys-random, with no policy for closest to expiring. The row of keys with an expiry holds volatile-lru, volatile-lfu, volatile-ttl and volatile-random. Below the grid, apart from it, noeviction: evict nothing and refuse writes.\"><text x=\"230.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">least recently used</text><text x=\"360.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">least frequently used</text><text x=\"490.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">closest to expiring</text><text x=\"620.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">at random</text><text x=\"170\" y=\"8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">how one is picked →</text><text x=\"158\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">any key</text><rect x=\"170\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-lru</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-lfu</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no such policy</text><rect x=\"560\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-random</text><text x=\"158\" y=\"127\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">only keys with an expiry</text><rect x=\"170\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-lru</text><rect x=\"300\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-lfu</text><rect x=\"430\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-ttl</text><rect x=\"560\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-random</text><text x=\"158\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">which keys may go ↓</text><rect x=\"170\" y=\"186\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">noeviction</text><text x=\"295.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">evict nothing, refuse writes</text></svg>", "caption": "Eight policies are two choices: which keys may go, and how one is picked among them. noeviction stands outside the grid, because it picks nothing."}
```

`allkeys-` means any key may go; `volatile-` means only keys with an expiry may go, and keys without
one are never touched. `lru` picks the key used least recently, `lfu` the one used least often,
`ttl` the one closest to expiring, `random` any. Redis does not keep a perfect ordering of millions
of keys: it samples a handful, five by default (`maxmemory-samples`), and evicts the best candidate
among them, which is close to the real thing and costs almost nothing.

## One load, three policies

To compare them fairly, every policy gets the same load. The shop has four products that every page
reads, and a flood of pages that are each written once and never read again. This file sets the
policy, writes the four products, then 40,000 pages, reading the four products after every 100 pages,
and reports what is left:

```sh
# fill.sh POLICY [TTL]: an empty Redis with that eviction policy, four products,
# then 40,000 pages of 100 bytes, reading the four products every 100 pages.
# With TTL, every page is written with that lifetime in seconds.
policy=$1
r() { docker exec redis redis-cli "$@"; }
r FLUSHALL > /dev/null
r CONFIG RESETSTAT > /dev/null
r CONFIG SET maxmemory-policy "$policy" > /dev/null
r MSET product:KB-101 34990 product:MS-204 18900 product:MN-330 149900 product:CB-012 3990 > /dev/null
refused=$(seq 1 40000 |
  awk -v ttl="$2" '{ printf "SET page:%d %0100d%s\n", $1, 0, (ttl ? " EX " ttl : "") }
    $1 % 100 == 0 { print "MGET product:KB-101 product:MS-204 product:MN-330 product:CB-012" }' |
  docker exec -i redis redis-cli | grep -c OOM)
echo "$policy${2:+ (pages with TTL)}: refused $refused, $(r INFO stats | grep ^evicted_keys | tr -d '\r'), keys left $(r DBSIZE), products left $(r EXISTS product:KB-101 product:MS-204 product:MN-330 product:CB-012) of 4"
```

Save it as `fill.sh` beside you, and run it under the three `allkeys-` policies, checking after
the first which pages it kept:

```
ana@vm:~$ sh fill.sh allkeys-lru
allkeys-lru: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ docker exec redis redis-cli EXISTS page:1
0
ana@vm:~$ docker exec redis redis-cli EXISTS page:40000
1
ana@vm:~$ sh fill.sh allkeys-lfu
allkeys-lfu: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ sh fill.sh allkeys-random
allkeys-random: refused 0, evicted_keys:22427, keys left 17430, products left 2 of 4
```

**All three made room, so nothing was refused**, and each evicted roughly the same number of keys:
enough to keep the total under 4 MB. The difference is which keys. `allkeys-lru` and `allkeys-lfu`
kept the four products, because the products were read every 100 pages and the pages were never
read at all. **`allkeys-random` evicted two of the four products**, because to a random
choice a product read thousands of times is worth exactly as much as a page nobody will read.

Under `allkeys-lru` the first page was gone and the last was there: the oldest pages, never read
since they were written, were the least recently used, so they went first.

## LRU or LFU

Both kept the products here, and they differ on a pattern this load did not have. LRU remembers only **when** a key was last used. So a single pass over many keys, a nightly report
reading every page once, makes all of them recent and pushes out the keys the shop reads all day. LFU keeps a small
counter of **how often** a key is used, which a single pass barely moves:

```
ana@vm:~$ sh fill.sh allkeys-lfu
allkeys-lfu: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ docker exec redis redis-cli OBJECT FREQ product:KB-101
11
ana@vm:~$ docker exec redis redis-cli OBJECT FREQ page:39999
5
```

`OBJECT FREQ` is that counter. The product, read every 100 pages, is at 11; a page written once
and never read is at 5, the value every new key starts with so that it is not evicted the
moment it arrives. The counter grows logarithmically and decays with time, so it measures
recent popularity rather than a lifetime total, and the two settings that tune it, `lfu-log-factor`
and `lfu-decay-time`, are left at their defaults here. For a cache whose hot keys are stable, a
catalogue, `allkeys-lfu` is the better default; for one where what is hot changes by the minute,
`allkeys-lru` follows it faster.
