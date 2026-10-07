---
title: Keeping Redis to itself
version: 1
---

Redis was designed for a trusted network, and **a Redis reachable from the internet with no password is
one of the most common ways servers are taken over**: anybody who can connect can read every key, delete
everything, and use its configuration commands to write files on the server's disk. Ubuntu's defaults
close that door, and they are worth knowing so that nobody opens it:

- `bind 127.0.0.1 -::1`: it listens on loopback only. An application on another machine needs a private
  network, or a tunnel, not a public address.
- `protected-mode yes`: if somebody does bind it to every address and sets no password, Redis refuses
  connections from anywhere but loopback anyway.

The third layer is **who may do what**, and Redis 6 and later answer that with ACLs. Out of the box
there is one user, `default`, with no password and every permission:

```
ana@web:~$ redis-cli ACL LIST
user default on nopass sanitize-payload ~* &* +@all
ana@web:~$ redis-cli ACL SETUSER shop on ">lab-shop-password" "~cache:*" +@read +@write -@dangerous
OK
```

`shop` may log in with a password, touch only keys that start with `cache:` (`~cache:*`), run read and
write commands, and none of the commands Redis classifies as **dangerous**: `FLUSHALL`, `CONFIG`,
`KEYS`, `DEBUG` and the rest. Logged in as `shop`:

```
ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning SET cache:book:2 "{}" EX 60
OK
ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning GET bestsellers
NOPERM this user has no permissions to access one of the keys used as arguments

ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning FLUSHALL
NOPERM this user has no permissions to run the 'flushall' command

ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning CONFIG GET requirepass
NOPERM this user has no permissions to run the 'config|get' command
```

It can cache a book under `cache:`, and it is refused everything else: another key, emptying the
database, reading the configuration. **An application whose Redis credentials can only touch its own
cache keys turns a leaked password from "everything" into "the cache"**, which is the same reasoning as
lesson 4's `ProtectSystem`.

The last command removes the user, because the lab's Redis stays open to `default` for the lessons that
follow. On a real server, the `default` user gets a password or is switched off (`ACL SETUSER default
off`), every application gets its own user, and the ACLs live in a file Redis loads at start
(`aclfile /etc/redis/users.acl`), so that a restart does not forget them.
