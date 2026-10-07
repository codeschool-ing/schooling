---
title: A cache and nothing else
version: 1
---

Memcached is older than Redis. It was written in 2003 for one site's problem, LiveJournal's database
falling behind its readers, and the answer was a server that holds values in memory under keys and
forgets them freely. **It has kept that single job ever since**, and the list of what it lacks is the
design rather than a backlog: no data types beyond bytes, no persistence, no replication, no scripting.

Ubuntu packages it as `memcached`, and lesson 1 installed it. Start it the way you
started Redis, and read its configuration:

```
ana@web:~$ sudo systemctl enable --now memcached && systemctl is-active memcached
Synchronizing state of memcached.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable memcached
active
ana@web:~$ grep -vE '^(#|$)' /etc/memcached.conf
-d
logfile /var/log/memcached.log
-m 64
-p 11211
-u memcache
-l 127.0.0.1
-P /var/run/memcached/memcached.pid
```

Each line of `/etc/memcached.conf` is a command-line option. **`-m 64` gives it 64 megabytes**, which
is not a ceiling it creeps towards but the memory it will hold once the cache is full. `-l 127.0.0.1`
keeps it on loopback, `-p 11211` is its port, and `-u memcache` drops root after it starts. Ubuntu's file
also carries `-l ::1`, the IPv6 loopback; the machine these transcripts came from has no IPv6, and the
line was deleted there.

There is no `redis-cli` for Memcached. It speaks plain text over TCP, so any program that can open a
socket can talk to it, and `nc`, netcat, is enough:

```
ana@web:~$ printf 'version\r\n' | nc -q1 127.0.0.1 11211
VERSION 1.6.24
```

**What Memcached has and Redis does not is threads.** Redis runs commands one at a time on one core,
which is why lesson 8's counters were never wrong. Memcached answers on four worker threads by default,
`-t 4`, so one server can use every core of a large machine. The price is a smaller vocabulary: no list
to trim, no set to intersect, nothing that the server must keep consistent across several keys at once.
