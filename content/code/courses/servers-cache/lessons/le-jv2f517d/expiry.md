---
title: Lifetimes, and the thirty-day line
version: 1
---

The second number after the key is the lifetime in seconds, and it behaves like Redis's `EX`: after
it runs out, the key is gone.

```
ana@web:~$ printf 'set session:7f3a 0 3 3\r\nana\r\nget session:7f3a\r\n' | nc -q1 127.0.0.1 11211; sleep 4; printf 'get session:7f3a\r\n' | nc -q1 127.0.0.1 11211
STORED
VALUE session:7f3a 0 3
ana
END
END
```

**Memcached expires lazily.** An expired item stays in memory until somebody asks for it or a
background thread, the LRU crawler, passes by; it is never returned either way, and its memory goes to
the next writes that need it.

The lifetime hides a trap Redis does not have. **A number up to 2,592,000, thirty days in seconds, is a
count of seconds from now. Anything larger is a moment, in Unix time.**

```
ana@web:~$ printf 'set month 0 2592000 1\r\nx\r\nset month-and-a-second 0 2592001 1\r\ny\r\nget month month-and-a-second\r\n' | nc -q1 127.0.0.1 11211
STORED
STORED
VALUE month 0 1
x
END
ana@web:~$ printf "set until 0 $(( $(date +%s) + 60 )) 1\r\nz\r\nget until\r\n" | nc -q1 127.0.0.1 11211
STORED
VALUE until 0 1
z
END
```

`month` asked for thirty days and was kept. `month-and-a-second` asked for one second more, which
Memcached read as one second past 31 January 1970, a moment more than fifty years gone, so the item
expired as it was written. Nothing failed, and `STORED` came back both times. **A cache that seems to
keep nothing with a long lifetime is usually this.** The fix is to send an absolute time, as the third
command did with `date +%s` plus sixty, or to stay under thirty days.

`touch` changes a lifetime without sending the value again:

```
ana@web:~$ printf 'set note 0 5 2\r\nhi\r\ntouch note 600\r\n' | nc -q1 127.0.0.1 11211; sleep 6; printf 'get note\r\n' | nc -q1 127.0.0.1 11211
STORED
TOUCHED
VALUE note 0 2
hi
END
```

The note had five seconds, `touch` gave it six hundred, and it was still there after six. That is how a
session is kept alive on every request without rewriting the session each time.
