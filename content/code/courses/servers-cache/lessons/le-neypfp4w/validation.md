---
title: Asking whether a copy is still good
version: 1
---

When a copy goes stale, a cache does not have to throw it away and download the whole response
again. It can ask the origin a much smaller question: **"I have this version; has it changed?"** That
is a **conditional request**, and the answer "no" is `304 Not Modified`, with no body.

The question needs a way to name the version the cache holds, and HTTP has two, both of which were
already on the stylesheet in lesson 1:

- **`ETag`**, an opaque tag for this exact content. The cache sends it back in `If-None-Match`.
- **`Last-Modified`**, a date. The cache sends it back in `If-Modified-Since`.

```
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -i etag
ETag: "6a96cc50-ed"
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: "6a96cc50-ed"' https://ipelivros.example/css/site.css
304 0 bytes
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: "6a96cc50-ee"' https://ipelivros.example/css/site.css
200 237 bytes
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-Modified-Since: Tue, 01 Sep 2026 13:00:00 GMT' https://ipelivros.example/css/site.css
304 0 bytes
```

The right tag gets `304` and zero bytes of body. A tag that is wrong by one character, which is what a
cache holds after the file changed, gets the whole file with its new tag. The date works the same way.
**When both are sent, `If-None-Match` wins**, because a date has one-second resolution and a file can
change twice within a second; a tag cannot be fooled that way.

## Strong and weak tags

```
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' https://ipelivros.example/js/app.js | grep -iE '^(etag|content-encoding)'
ETag: W/"6a96cc50-1ce"
Content-Encoding: gzip
```

The same script, asked for compressed, gets a tag beginning with `W/`: a **weak** tag. Nginx marks it
weak because the compressed bytes are not the bytes the tag was computed from; the content means the
same thing, and the bytes differ. A weak tag is good for "has it changed?" and not for anything that
depends on exact bytes, such as resuming a download half-way through a file.

## Validation saves bandwidth, not work

The shop computes an `ETag` for every book from the bytes of its JSON, and answers `If-None-Match` with
a `304`, as an application should:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://ipelivros.example/api/books/1
200 124 bytes in 0.154089 s
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' -H 'If-None-Match: "806121fbab2ee803"' https://ipelivros.example/api/books/1
304 0 bytes in 0.158108 s
ana@web:~$ curl -s localhost:8001/api/stats; curl -s localhost:8002/api/stats
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 1}
```

`304` and no body, and **the same 0.15 seconds**, because the shop still ran the database query to
build the response it then hashed and compared. One query for each request, on each shop. The `304` saved
the 124 bytes of the body on the network and saved nothing of the work, and for a twelve-row
catalogue on a local network the body was never the expensive part.

That is the general rule: **validation saves the transfer; only freshness saves the work.** An
application can do better than the shop does by keeping something cheap to compare with, a version
number or an `updated_at` column, and answering the `304` before it builds the response. Even then it
still receives the request. The way to stop the request reaching the application at all is a copy
that is fresh, kept in front of it, which is the next section.
