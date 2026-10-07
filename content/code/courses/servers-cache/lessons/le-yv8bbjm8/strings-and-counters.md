---
title: Strings, counters and a lock
version: 1
---

`redis-cli` sends one command and prints the answer. The simplest type is a **string**, and a key is any
name you like; the convention is words separated by colons, from general to specific, `views:book:2`,
so that related keys sort and scan together.

```
ana@web:~$ redis-cli SET greeting "Bem-vindo à Ipê Livros"
OK
ana@web:~$ redis-cli GET greeting
Bem-vindo à Ipê Livros
ana@web:~$ redis-cli GET nothing-here
```

A key that does not exist answers with nothing, which `redis-cli` prints as an empty line. Strings are
bytes, so the accents came back exactly as they went in.

## Counters

```
ana@web:~$ redis-cli SET views:book:2 0 && redis-cli INCR views:book:2 && redis-cli INCRBY views:book:2 10
OK
1
11
```

**`INCR` reads, adds and writes in one step.** An application that did `GET`, added one in its own code
and did `SET` would lose increments whenever two copies of it did that at the same moment; `INCR` cannot,
because Redis runs one command at a time. `INCRBY` adds any amount, and both create the key at 0 if it is
missing. A view counter, a rate limit, a sequence number for orders: each is one `INCR`.

## Set only if absent

```
ana@web:~$ redis-cli SET lock:report ana NX; redis-cli SET lock:report bruno NX; redis-cli GET lock:report
OK

ana
ana@web:~$ redis-cli TYPE views:book:2; redis-cli OBJECT ENCODING views:book:2
string
int
```

`NX` means "only if the key does not exist". The first `SET` wrote `ana` and answered `OK`; the second
found the key there and wrote nothing, answering with nothing. That is a **lock** in one command: the
process that gets `OK` holds it, and the others know they do not. Lesson 11 uses exactly this to make
sure only one request rebuilds an expired value.

The last line is a reminder that types are real. `views:book:2` is a string whose content is a number,
and Redis stores it as an integer, `int`, which takes less memory than the text would.
