---
title: Memcached or Redis
version: 1
---

Both keep values in memory under keys, both evict, both answer in well under a millisecond on loopback.
Where they differ is everything around that:

| | Memcached | Redis |
|---|---|---|
| values | bytes, up to 1 MB by default | strings, hashes, lists, sets, sorted sets and more |
| threads | several worker threads | commands run one at a time |
| when memory is full | evicts, least recently used per slab class | what `maxmemory-policy` says; Ubuntu refuses writes |
| after a restart | empty | what RDB or AOF kept |
| several servers | the client hashes keys over them | the client, or Redis Cluster |
| atomic changes | `incr`, `decr`, `add`, `cas` | every command, plus `MULTI` and scripts |
| access control | the address it listens on; an optional password file | the address, protected mode, ACL users |

**Memcached fits a pure cache of whole objects.** Rendered fragments, serialised records, the results of
expensive queries: values written whole, read whole, and never missed when they are gone. On a machine
with many cores and a lot of memory, its threads make one server do the work Redis would spread over
several processes.

**Redis fits when the cache needs to be more than a dictionary**: a ranking kept sorted, a counter per
field, a recent-items list trimmed on every push, a lifetime per key it can report on. It also fits
when Redis is already running for something else, because a second system has a cost of its own:
another service to patch, watch and secure.

The next two lessons use Redis, for commands Memcached lacks. Every pattern in them still works over
Memcached, with `add` where they take a lock and `cas` where they check what is there before writing.
