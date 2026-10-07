---
title: Purging one URL, and purging by tag
version: 1
---

Lesson 6 replaced one copy at a time, by URL. An edge can do that too, and it can do something Nginx
cannot: remove **every copy that carries a tag**, whatever its URL.

## One URL

`PURGE` is not an HTTP method any standard defines; it is a convention that Varnish, Squid and many
CDNs' APIs share. The `vcl_recv` above accepts it from `purgers` only:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/5 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 18
Age: 0
X-Cache: MISS
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -X PURGE -H 'Host: ipelivros.example' http://localhost:6081/api/books/5
200
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/5 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 21
Age: 0
X-Cache: MISS
```

A copy, a `PURGE` answered `200`, and the next request missed and fetched it again. A `PURGE` from an
address outside the list gets `403`, and that list is the difference between a purge feature and a way
for anybody to empty the cache.

## By tag

The price of book 2 appears on its own page and on the listing. Purging by URL needs both URLs, and
whoever changes the price has to know every page that shows it. **Tags turn that around: each response
says what it contains, and a purge names the thing that changed.** The origin labels the book's page
`book-2` and the listing `listing`. The `BAN` handler turns a header into a **ban**, a rule that every
stored object is checked against, and a price change becomes one request:

```
ana@web:~$ for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' $p; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081$p | grep -i x-cache; done
/api/books     X-Cache: HIT
/api/books/2   X-Cache: HIT
/api/books/6   X-Cache: HIT
ana@web:~$ curl -s -X PUT -d '{"price_cents": 7490}' -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7490}
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -X BAN -H 'X-Ban-Tags: \b(book-2|listing)\b' -H 'Host: ipelivros.example' http://localhost:6081/
200
ana@web:~$ for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' $p; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081$p | grep -i x-cache; done
/api/books     X-Cache: MISS
/api/books/2   X-Cache: MISS
/api/books/6   X-Cache: HIT
```

```
ana@web:~$ curl -s -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7490}
ana@web:~$ sudo varnishadm ban.list
Present bans:
1791346659.490675     3 -  obj.http.Surrogate-Key ~ \b(book-2|listing)\b
1791346651.698669     3 C  
```

The listing and book 2 missed, book 6 was untouched, and the new price came through on the first
request. `ban.list` shows the rule, kept until every object older than it has been checked; Varnish
tests objects lazily, as they are requested, and a background thread clears the rest.

The tag in the header is a regular expression, and `\b` marks a word boundary, so that `book-2` does
not also match `book-21`. Commercial CDNs offer the same thing under other names: Fastly's **surrogate
keys** (the header name used here), Cloudflare's **cache tags**, Akamai's **cache tags**. The idea is
always the one in this section: the origin says what is in a response, and invalidation names what
changed.
