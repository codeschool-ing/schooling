---
title: The key at the edge
version: 1
---

An edge stores one copy per key, and its default key is the URL and the host. Every difference in the
URL is a different copy, including differences that change nothing for the origin, and the commonest of
those are **tracking parameters**: `?utm_source=news` on a link in a newsletter, `?utm_source=ads&utm_medium=cpc`
on an advertisement. The page is the same, and without care each variant is a separate miss at every
edge in the world.

The first two lines of `vcl_recv` remove every `utm_` parameter before the key is computed:

```
ana@web:~$ for q in '?utm_source=news' '?utm_source=ads&utm_medium=cpc' '' '?page=2'; do printf '%-34s ' "$q"; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' "http://localhost:6081/api/books/4$q" | grep -i x-cache; done
?utm_source=news                   X-Cache: MISS
?utm_source=ads&utm_medium=cpc     X-Cache: HIT
                                   X-Cache: HIT
?page=2                            X-Cache: MISS
```

The first request missed and stored the book under its clean URL. The second, with two different
tracking parameters, was **a hit on the same copy**, and so was the URL with no query at all. `?page=2`
is a real parameter, one the origin could answer differently, so it stayed in the key and missed.

This is the edge's version of lesson 5's rule, turned around. There, the key had to include everything
that changes the answer, or one person's answer reached another. Here, it should include nothing that
does not, or the cache fills with duplicates and the hit ratio falls. Both mistakes are in the key, and
both are found the same way: by reading the hit and miss headers for URLs that should, and should not,
share a copy.
