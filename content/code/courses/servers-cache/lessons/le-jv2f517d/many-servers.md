---
title: One cache over several servers
version: 1
---

Memcached servers do not know about each other. **The client spreads the keys**: it hashes each key and
picks a server from the hash, so every client holding the same list sends the same key to the same
server. Start two more, on ports 11212 and 11213:

```
ana@web:~$ sudo memcached -d -u memcache -l 127.0.0.1 -p 11212 -m 64 && sudo memcached -d -u memcache -l 127.0.0.1 -p 11213 -m 64 && pgrep -a memcached
1769 /usr/bin/memcached -m 64 -p 11211 -u memcache -l 127.0.0.1 -P /var/run/memcached/memcached.pid
1828 memcached -d -u memcache -l 127.0.0.1 -p 11212 -m 64
1840 memcached -d -u memcache -l 127.0.0.1 -p 11213 -m 64
```

This program gives a thousand keys to a client that knows two of them:

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "from pymemcache.client.hash import HashClient\n\nservers = [(\"127.0.0.1\", 11211), (\"127.0.0.1\", 11212)]\nmc = HashClient(servers, default_noreply=False)\nfor i in range(1000):\n    mc.set(f\"book:{i}\", b\"1\")\nprint(\"book:7 lives on\", mc.hasher.get_node(\"book:7\"))\n", "note": "A thousand keys through a client that knows two servers, and the server `book:7` went to."}]}
```

```
ana@web:~/work$ python3 spread.py
book:7 lives on 127.0.0.1:11212
ana@web:~/work$ for p in 11211 11212; do printf 'stats\r\n' | nc -q1 127.0.0.1 $p | grep ' curr_items '; done
STAT curr_items 513
STAT curr_items 487
```

513 keys went to one server and 487 to the other, `book:7` among the second lot. Neither server knows
the other holds half the cache.

The obvious way to choose a server is the hash modulo the number of servers. It spreads keys evenly and
**fails the day a server is added**, because with three servers instead of two most hashes land on a
different one. `HashClient` uses **rendezvous hashing**: for each key it scores every server, from a
hash of the server's name and the key together, and takes the highest. A new server wins the keys where
its score is now the highest, and no other key moves. This program counts both:

```schooling-example
{"language": "python", "file": "moves.py", "parts": [{"code": "import zlib\n\nfrom pymemcache.client.rendezvous import RendezvousHash\n\nkeys = [f\"book:{i}\" for i in range(10000)]\n\n\ndef modulo(key, n):\n    return zlib.crc32(key.encode()) % n\n\n\ndef rendezvous(key, n):\n    return RendezvousHash(nodes=list(range(n))).get_node(key)\n\n\nfor name, place in ((\"modulo\", modulo), (\"rendezvous\", rendezvous)):\n    moved = sum(place(k, 2) != place(k, 3) for k in keys)\n    print(f\"{name:>10}: {moved} of {len(keys)} keys move ({moved / len(keys):.0%})\")\n", "note": "Counts the keys that change server when two servers become three, by modulo and by rendezvous."}]}
```

```
ana@web:~/work$ python3 moves.py
    modulo: 6591 of 10000 keys move (66%)
rendezvous: 3327 of 10000 keys move (33%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 170\" role=\"img\" aria-label=\"Two bars, each standing for 10,000 keys when a third server joins two. Modulo: 6,591 keys move, two thirds of the bar. Rendezvous: 3,327 keys move, one third of the bar.\"><defs><marker id=\"frh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10,000 keys, two servers become three</text><text x=\"130\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">modulo</text><rect x=\"145\" y=\"40\" width=\"316.368\" height=\"28\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.7\"></rect><rect x=\"461.368\" y=\"40\" width=\"163.632\" height=\"28\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.4\"></rect><text x=\"303.18399999999997\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6,591 move</text><text x=\"543.184\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stay</text><text x=\"130\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rendezvous</text><rect x=\"145\" y=\"95\" width=\"159.696\" height=\"28\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.7\"></rect><rect x=\"304.696\" y=\"95\" width=\"320.304\" height=\"28\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.4\"></rect><text x=\"224.848\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3,327 move</text><text x=\"464.848\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stay</text><text x=\"350\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every key that moves is a miss</text></svg>", "caption": "Adding a server costs a miss for every key that moves. Rendezvous hashing moves only the keys the new server takes over."}
```

From two servers to three, modulo moved two keys in three and rendezvous one in three, the third that
the new server ought to own. **Every key that moves is a miss**, answered by the database while the
cache refills, so the gap between those two numbers is the gap between a third and two thirds of the
traffic reaching the database at once. Consistent hashing, which puts servers and keys on a ring, gets
the same property another way, and many Memcached clients use it.

A server that stops answering is the same event the other way round: its share of the keys becomes
misses and the others carry on. A cache is allowed to lose data, and that is the moment the database
pays for it.

When you have finished with them, stop the two extra servers:

```sh
sudo kill $(pgrep -f 'memcached -d -u memcache')
```
