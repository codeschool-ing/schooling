---
title: Deleting a copy from disk
version: 1
---

The other way to make Nginx forget a copy is to delete the file it is kept in. Lesson 5 showed that
each copy is a file whose first line is its key; the file's **name** is the MD5 of that key, and its
directories are taken from the end of the name, because the cache was declared with `levels=1:2`:

```
ana@web:~$ curl -s -X PUT -d '{"price_cents": 6990}' https://ipelivros.example/api/books/2 > /dev/null; curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":7990}
X-Cache-Status: HIT
ana@web:~$ echo -n 'http://shop/api/books/2' | md5sum
e8fb3bb9dc4188361a54f7d7c9036679  -
ana@web:~$ K=$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo ls -l /var/cache/nginx/shop/${K: -1}/${K: -3:2}/$K
-rw------- 1 www-data www-data 764 Oct  7 01:09 /var/cache/nginx/shop/9/67/e8fb3bb9dc4188361a54f7d7c9036679
ana@web:~$ K=$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo rm /var/cache/nginx/shop/${K: -1}/${K: -3:2}/$K
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":6990}
X-Cache-Status: MISS
```

The price changed to 6,990, the cache still said 7,990, and after the file was removed the next request
was a `MISS` that fetched the new one. The path is the last character of the hash (`9`), then the two
before it (`67`), then the hash itself, which is what `levels=1:2` means.

This works, and it is how scripts that "purge" open-source Nginx do it. Two cautions come with it. The
key has to be exactly the one Nginx computed, scheme and upstream name included, or the hash points at
nothing and the delete silently does nothing; and on a server with several Nginx machines, the copy has
to be deleted on every one of them. A refresh request through the front door, as in the previous
section, has neither problem, which is why it is usually the better tool of the two.
