---
title: What the edge will not keep
version: 1
---

Lesson 5 found that Nginx served its shared copy to a request carrying an `Authorization` header, and
needed two lines to stop. Varnish's built-in logic makes the opposite choice:

```
ana@web:~$ for i in 1 2; do curl -s -o /dev/null -D - -H 'Host: ipelivros.example' -H 'Cookie: session=abc' http://localhost:6081/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done
X-Varnish: 7
X-Cache: MISS
X-Varnish: 32774
X-Cache: MISS
ana@web:~$ for i in 1 2; do curl -s -o /dev/null -D - -H 'Host: ipelivros.example' -H 'Authorization: Bearer abc' http://localhost:6081/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done
X-Varnish: 10
X-Cache: MISS
X-Varnish: 32777
X-Cache: MISS
```

**A miss every time, and a single transaction number: Varnish did not even look in its cache.** A
request that carries a `Cookie` or an `Authorization` header is **passed** straight to the origin and
its answer is not stored, because either header usually means the answer belongs to one person.
Varnish's built-in rules also refuse to store a response that sets a cookie, and anything whose
`Cache-Control` says `private`, `no-cache` or `no-store`.

That is the safe default, and it has a cost that surprises everybody who puts a CDN in front of a real
site: **almost every browser request carries a cookie.** An analytics script, a consent banner or a
language preference sets one on the site's domain, every later request sends it, and the edge passes
them all. A site behind a CDN with a hit ratio near zero has usually met this. The fix is to remove, at
the edge, the cookies the origin never reads for a given path (a stylesheet needs none), and never to
switch the rule off wholesale, which is lesson 5's leak with a bigger audience.
