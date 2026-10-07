---
title: Two copies of the application
version: 1
---

One copy of the shop is one process, and one process is a single point of failure as well as a
ceiling on how much work gets done. The shop runs as two, on ports 8001 and 8002, and an
**upstream** block names them as a group that `proxy_pass` can point at:

```conf
upstream shop {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
```

`proxy_pass http://shop` now names the group instead of an address. The default way of sharing
requests between its members is **round robin**: each in turn. Six requests, then:

```
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
```

That is not each in turn, and it is worth understanding why before trusting anything this lesson
measures. **Every Nginx worker keeps its own round-robin position.** Each `curl` opens a new
connection, the kernel hands it to whichever of the four workers is free, and each worker starts its
own count at `shop1`. Over many requests it evens out:

```
ana@web:~$ for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     50 shop1
     50 shop2
```

Fifty-fifty over a hundred. Over six it looked broken. The fix is `zone`, which puts the group's
state in memory shared by every worker, so there is one round-robin position instead of four:

```
ana@web:~$ sudo sed -i 's/^upstream shop {/upstream shop {\n    zone shop 64k;/' /etc/nginx/sites-available/ipelivros && sed -n '1,6p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
X-Served-By: shop2
```

**`zone` belongs in every upstream block you write.** Without it, every per-member counter is
counted four times over: the turn, the failures of the section after next, and the connections that
`least_conn` balances on. Nothing reports the difference. It shows up as behaviour that looks almost
right.

## Keeping connections to the application open

The three lines that are new in the location are about one thing. By default Nginx opens a new
connection to the application for every request and closes it afterwards, which for a small JSON
answer can cost more than the answer. `keepalive 16` lets each worker keep up to sixteen idle
connections to the group, and they are reused only over HTTP/1.1 with the `Connection` header
cleared, hence `proxy_http_version 1.1` and `proxy_set_header Connection ""`. After the hundred
requests above, the connections are still there, waiting:

```
ana@web:~$ sudo ss -Htn state established '( dport = :8001 or dport = :8002 )' | wc -l
8
```

Eight open connections from Nginx to the two shops, across four workers. Without `keepalive`, Nginx
closes each one when its request is done, and every new request pays for a TCP handshake first.
