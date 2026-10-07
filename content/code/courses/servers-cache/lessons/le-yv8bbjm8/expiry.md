---
title: Keys that expire
version: 1
---

Every key can carry a lifetime, and for a cache it is the most important property a key has: lesson 6
argued that **a lifetime is the backstop when every invalidation fails**, and Redis is where that
backstop lives for application data.

```
ana@web:~$ redis-cli SET session:7f3a ana EX 30
OK
ana@web:~$ redis-cli TTL session:7f3a; redis-cli PTTL session:7f3a
30
29945
ana@web:~$ redis-cli TTL greeting; redis-cli TTL nothing-here
-1
-2
```

`EX 30` sets thirty seconds as the key is written; `TTL` counts down in seconds and `PTTL` in
milliseconds. The two special answers are worth memorising: **`-1` means the key exists and never
expires**, which is what `greeting` was given by a plain `SET`, and **`-2` means there is no such key**.

```
ana@web:~$ redis-cli EXPIRE greeting 2 && sleep 3 && redis-cli GET greeting
1

ana@web:~$ redis-cli PERSIST session:7f3a && redis-cli TTL session:7f3a
1
-1
```

`EXPIRE` adds a lifetime to an existing key, and three seconds later the key was gone. `PERSIST` takes a
lifetime away, and the session is back to `-1`, which on a cache server is how keys pile up until memory
runs out.

Redis removes expired keys in two ways at once. **Lazily**: a key whose time has passed is deleted the
moment anybody asks for it, so nobody ever reads an expired value. And **actively**: several times a
second it samples some keys with a lifetime and deletes the expired ones it finds, so that keys nobody
asks for again do not sit in memory for ever. Between the two, an expired key can occupy memory for a
little while, and never be returned.
