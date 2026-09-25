---
title: HTTP by hand
version: 1
---

HTTP/1.1 is text, and a person can speak it. `nc` opens a TCP connection to port 80 and sends whatever
it is given; `printf` gives it a request, each line ended with `\r\n` and the whole request ended
with an empty line:

```
ana@laptop:~$ printf 'GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n' | nc -w 3 192.0.2.80 80
HTTP/1.1 301 Moved Permanently
Server: nginx/1.24.0 (Ubuntu)
Date: Fri, 25 Sep 2026 16:57:45 GMT
Content-Type: text/html
Content-Length: 178
Connection: close
Location: https://www.example.com/

<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx/1.24.0 (Ubuntu)</center>
</body>
</html>
```

A request is a **request line**, `GET / HTTP/1.1`, then **headers**, one per line. `Host:` is the one
that matters most: one web server, at one address, can serve many sites, and `Host:` says which one.
It is how `example.com`, `www.example.com` and `shop.example.com` all live on `192.0.2.80`.

The answer has the same shape: a **status line**, `HTTP/1.1 301 Moved Permanently`, headers, an empty
line, and a body. The status says this is not the page; **`Location:`** says where it is, and the body
is a small page for anybody who reads it anyway. This server sends every plain HTTP request to the
same address over HTTPS, and it does so for every path, as `curl -v` shows with `>` for what was sent
and `<` for what came back:

```
ana@laptop:~$ curl -sv -o /dev/null http://www.example.com/prices.txt 2>&1 | grep "^[<>]"
> GET /prices.txt HTTP/1.1
> Host: www.example.com
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Server: nginx/1.24.0 (Ubuntu)
< Date: Fri, 25 Sep 2026 16:57:45 GMT
< Content-Type: text/html
< Content-Length: 178
< Connection: keep-alive
< Location: https://www.example.com/prices.txt
< 
```

`/prices.txt` over HTTP is answered with a redirect to `/prices.txt` over HTTPS. No page is ever
served in plain text. The next lesson is what makes the HTTPS answer trustworthy; this one is what it
looks like on the wire.
