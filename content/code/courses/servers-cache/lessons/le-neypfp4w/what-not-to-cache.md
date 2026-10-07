---
title: What a shared cache must never keep
version: 1
---

A browser's cache holds one person's copies. A shared cache hands its copies to **everybody**, and the
worst thing it can do is not to be slow or out of date: it is to give one person's page to somebody
else. Incidents of that kind share one shape, an account page or a basket cached once and then served
to whoever asked for the same URL next, and the defence is three rules.

**One: anything that differs per person says `private` or `no-store`, and the shared cache obeys.**
Nginx does, as the previous section showed: three requests for a `private` response, three trips to
the shop, nothing stored. The responsibility is split. The application has to send the header on every
personal response, including error pages and redirects; the cache has to honour it, which Nginx does by
default and which one line switches off, `proxy_ignore_headers Cache-Control`. That line turns up in
advice about squeezing more hits out of a cache, and it is the line that turns a cache into a leak.

**Two: the key has to contain everything that changes the answer.** The key includes the query string,
so `?a=1` and `?a=2` are stored apart, and the second `?a=1` is a hit:

```
ana@web:~$ for q in '' '?a=1' '?a=2' '?a=1'; do printf '%-6s ' "$q"; curl -s -o /dev/null -D - "https://ipelivros.example/api/books/5$q" | grep -i x-cache-status; done
       X-Cache-Status: MISS
?a=1   X-Cache-Status: MISS
?a=2   X-Cache-Status: MISS
?a=1   X-Cache-Status: HIT
```

Now two requests the cache treats exactly like the first:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Cache-Control: no-cache' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
```

**Both were served from the cache.** The first asked for a fresh copy with `Cache-Control: no-cache`, and
Nginx ignores what clients ask for, by design: otherwise any client could force every request through to
the application. The second carried an `Authorization` header, **and Nginx gave it the copy stored for
everybody**. Nginx does not look at credentials when it decides what to serve. If the API ever answered
differently for a logged-in user, that user's answer would be stored under the same key and handed to
the next anonymous visitor, or the other way round. The defence is two lines in the location:

```
ana@web:~$ sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_bypass $http_authorization;\n        proxy_no_cache     $http_authorization;|' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache\|proxy_no_cache' /etc/nginx/sites-available/ipelivros
27:        proxy_cache api_cache;
28:        proxy_cache_bypass $http_authorization;
29:        proxy_no_cache     $http_authorization;
ana@web:~$ curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: BYPASS
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
```

`BYPASS` for the request with credentials, which went to the shop and was not stored
(`proxy_no_cache`), and `HIT` for the one without. Nginx does refuse on its own to store a response that
sets a cookie (`Set-Cookie`), for the same reason; a request that carries one is up to you, with the same
two directives and `$http_cookie`.

**Three: if the answer varies on something that is not in the URL, the key or `Vary` must say so.** A
language chosen from `Accept-Language`, or a currency from a cookie, changes the answer without
changing the URL. Either the key includes it (`proxy_cache_key "$scheme$host$request_uri$cookie_currency"`)
or the response carries `Vary: Accept-Language`, which Nginx respects by storing one copy per value. The
bookshop varies on nothing else, which is why its key needed nothing more.

What to put in a shared cache, then: public responses, the same for every visitor, whose staleness for a
minute costs nothing. **When in doubt, leave it out**: a cache that misses costs a few milliseconds, and a
cache that serves the wrong person costs a notification to the data protection authority.
