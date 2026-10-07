---
title: Speaking the protocol by hand
version: 1
---

A Memcached command is one line ending in `\r\n`, a carriage return and a line feed. A command that
stores something is followed by a second line, the data. `printf` writes both, and `nc -q1` sends them
and waits a second for whatever comes back:

```
ana@web:~$ printf 'set greeting 0 0 5\r\nhello\r\n' | nc -q1 127.0.0.1 11211
STORED
ana@web:~$ printf 'get greeting\r\n' | nc -q1 127.0.0.1 11211
VALUE greeting 0 5
hello
END
ana@web:~$ printf 'get nothing-here\r\n' | nc -q1 127.0.0.1 11211
END
```

**`set greeting 0 0 5` reads as key, flags, lifetime, length.** The flags are a number Memcached keeps
and hands back without ever reading it, for the client's own use, and the section on Python puts them
to work. A lifetime of 0 means none. The length is the number of bytes in the data line and it has to be
exact, because Memcached reads that many bytes and then expects `\r\n`. A `get` answers with one
`VALUE` line per key it found and finishes with `END`, so **a miss is an `END` with nothing before it**,
not an error.

Two stores with a condition, and two counters:

```
ana@web:~$ printf 'add greeting 0 0 3\r\nbye\r\nreplace nothing-here 0 0 3\r\nbye\r\n' | nc -q1 127.0.0.1 11211
NOT_STORED
NOT_STORED
ana@web:~$ printf 'set views 0 0 1\r\n0\r\nincr views 5\r\ndecr views 9\r\nincr greeting 1\r\n' | nc -q1 127.0.0.1 11211
STORED
5
0
CLIENT_ERROR cannot increment or decrement non-numeric value
```

`add` stores only when the key is absent and `replace` only when it is present, so both answered
`NOT_STORED`. `add` is the tool lesson 8 met as `SET … NX`: a lock that the first client to ask
receives. **`incr` and `decr` are atomic, and `decr` stops at zero.** Five minus nine gave 0 rather
than -4, because the counters are unsigned 64-bit numbers, and incrementing text is refused outright.

```
ana@web:~$ printf 'delete greeting\r\ndelete greeting\r\n' | nc -q1 127.0.0.1 11211
DELETED
NOT_FOUND
```

`delete` says whether there was anything to delete. What the protocol does not offer is a way to
browse: there is no `KEYS` and no `SCAN`. **Memcached is built to be asked for a key you already
know**, which is exactly how an application uses a cache, and exactly what makes it awkward to inspect
by hand.
