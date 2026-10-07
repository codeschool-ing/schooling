---
title: What the server says about itself
version: 1
---

Hardening a web server is mostly two habits: **say less about yourself, and refuse more of what you
were not built to answer.** Neither makes a vulnerable program safe. Both make the server harder to
map, and a mapped server is the one that gets attacked first when a vulnerability in its version is
published. This lesson applies both to the bookshop, one setting at a time, and each one is checked
from the outside before and after.

Start with what the server announces to anybody who asks:

```
ana@web:~$ curl -sI https://ipelivros.example/ | grep -i ^server
Server: nginx/1.24.0 (Ubuntu)
ana@web:~$ curl -s https://ipelivros.example/nothing-here | grep -i nginx
<hr><center>nginx/1.24.0 (Ubuntu)</center>
```

**The exact version, on every response and on every error page.** The day a flaw in Nginx 1.24 is
published, every scanner on the internet can make a list of the servers that carry it by asking
once. Hiding the version does not remove the flaw, and a determined attacker can often guess a
version from behaviour; what it removes is the free list.

The shop announces itself too, on its own port:

```
ana@web:~$ curl -sI http://localhost:8001/healthz | grep -i ^server
Server: ipe-shop/1.0
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(server|x-served-by)"
Server: nginx/1.24.0 (Ubuntu)
X-Served-By: shop1
```

Through Nginx, the shop's `Server: ipe-shop/1.0` is gone, replaced by Nginx's own. **A proxy does not
pass the application's `Server` header on by default**, which is one quiet benefit of having one;
headers like `X-Served-By`, which the shop invented, pass through unchanged, and the last section
of this lesson comes back to whether that one should.

Ubuntu ships the line that hides the version, commented out:

```
ana@web:~$ sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf && grep -n server_tokens /etc/nginx/nginx.conf
21:	server_tokens off;
ana@web:~$ curl -sI https://ipelivros.example/ | grep -i ^server
Server: nginx
ana@web:~$ curl -s https://ipelivros.example/nothing-here | grep -i nginx
<hr><center>nginx</center>
```

`nginx` with no number, in the header and on the error page. One line in `http { }` covers every site.

**What a response should not carry, as a list to check your own server against:** a version number in
`Server` or in `X-Powered-By`; a stack trace or a framework's debug page on an error; directory
listings (`autoindex`, off by default in Nginx); and internal host names or addresses in headers or
redirects. Each of them is information an attacker would otherwise have to work for.
