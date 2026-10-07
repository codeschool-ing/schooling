---
title: An edge of your own, with Varnish
version: 1
---

**Varnish** is a cache that does nothing but cache HTTP, and the CDN Fastly grew out of it. It is in Ubuntu's archive and `lab.sh install` put it on your server, stopped. Here it plays
the edge, and Nginx plays the origin.

The origin needs one more server block: plain HTTP, on an address only the machine itself reaches,
serving the same site with no cache of its own, so that the edge is the only one in this picture. It
also labels each API response with a `Surrogate-Key` header, which the section on purging by tag uses:

```
ana@web:~$ cat /etc/nginx/sites-available/origin
# The origin, as the edge sees it: plain HTTP, on an address only this
# machine can reach. Every response carries the tags the edge purges by.
server {
    listen 127.0.0.1:8080;
    server_name ipelivros.example;

    root /var/www/ipe;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /healthz {
        proxy_pass http://shop;
    }

    location = /api/books {
        proxy_pass http://shop;
        add_header Surrogate-Key "listing";
    }

    location ~ ^/api/books/(\d+)$ {
        proxy_pass http://shop;
        add_header Surrogate-Key "book-$1";
    }
}
ana@web:~$ sudo ln -s ../sites-available/origin /etc/nginx/sites-enabled/origin
ana@web:~$ curl -sI -H 'Host: ipelivros.example' http://127.0.0.1:8080/api/books/2 | grep -iE '^(HTTP|cache-control|surrogate-key|x-served-by)'
HTTP/1.1 200 OK
X-Served-By: shop1
Cache-Control: public, max-age=60
Surrogate-Key: book-2
```

The origin still answers with the shop's `Cache-Control: public, max-age=60`, and now a tag. Varnish is
configured in **VCL**, a small language with one function per stage of a request. This file names the
origin and how to check its health, who may purge, and three small policies, each explained in the
section that uses it:

```conf
vcl 4.1;

# The origin: Nginx on 127.0.0.1:8080, asked every two seconds whether it is
# well, and treated as sick after two failed answers out of three.
backend origin {
    .host = "127.0.0.1";
    .port = "8080";
    .probe = {
        .url = "/healthz";
        .interval = 2s;
        .timeout = 1s;
        .window = 3;
        .threshold = 2;
    }
}

# Who may purge. On a real edge, the machines that publish content.
acl purgers {
    "127.0.0.1";
}

sub vcl_recv {
    # Tracking parameters change the URL and never the answer.
    set req.url = regsuball(req.url, "(?<=[?&])utm_[a-z]+=[^&]*&?", "");
    set req.url = regsub(req.url, "[?&]$", "");

    if (req.method == "PURGE") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        return (purge);
    }
    if (req.method == "BAN") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        ban("obj.http.Surrogate-Key ~ " + req.http.X-Ban-Tags);
        return (synth(200, "Banned"));
    }
}

sub vcl_backend_response {
    # Keep an expired object for an hour, to serve while the origin is
    # fetched again or while it is down.
    set beresp.grace = 1h;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    # The tags are for the edge, not for the public.
    unset resp.http.Surrogate-Key;
}
```

What the file does not say matters as much: everything else is **Varnish's built-in logic**, which runs
after each of these functions unless the function returns first. It is the reason the file can be this
short, and the next section is about the most important thing it does.

```
ana@web:~$ sudo varnishd -C -f /etc/varnish/default.vcl > /dev/null 2>&1 && echo "VCL compiles"
VCL compiles
ana@web:~$ sudo systemctl start varnish && systemctl is-active varnish
active
ana@web:~$ sudo ss -ltnp | grep -E ':(6081|6082|8080) ' | awk '{print $4, $6}'
127.0.0.1:8080 users:(("nginx",pid=1370,fd=21),("nginx",pid=1369,fd=21),("nginx",pid=1368,fd=21),("nginx",pid=1367,fd=21),("nginx",pid=177,fd=21))
0.0.0.0:6081 users:(("cache-main",pid=1431,fd=3),("varnishd",pid=1405,fd=3))
127.0.0.1:6082 users:(("varnishd",pid=1405,fd=6))
```

Varnish listens on 6081 for visitors and on 6082, loopback only, for its administration commands. Ask it
for a book three times:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 2
Age: 0
X-Cache: MISS
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 32770 3
Age: 0
X-Cache: HIT
ana@web:~$ sleep 3; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 5 3
Age: 3
X-Cache: HIT
ana@web:~$ curl -sI -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(via|surrogate-key|x-served-by)'
X-Served-By: shop2
Via: 1.1 varnish (Varnish/7.1)
```

Three headers tell an edge's story, and every CDN has its own spelling of them. **`X-Varnish`** carries
one transaction number on a miss and two on a hit: this request's, and the one that stored the copy.
**`Age`** is how many seconds the copy has been at the edge, 3 after the `sleep 3`; a visitor's browser
subtracts it from `max-age`, so a copy that spent 50 of its 60 seconds at the edge is fresh in the
browser for only 10 more. And **`Via`** says a proxy was on the way. The tag is gone, removed in
`vcl_deliver`, as it should be, since it describes the site's internals.
