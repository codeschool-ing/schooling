---
title: The server that works
version: 1
---

The server gets a web server that works, and a page that says so:

```
ana@server:~$ sudo systemctl enable --now nginx 2>&1 | tail -1; echo "lab server: ok" | sudo tee /var/www/html/index.html
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
lab server: ok
ana@client:~$ curl -sS http://server/
lab server: ok
```

`systemctl enable --now` does two things at once: starts nginx now, and starts it at every boot. The
page is one line, written with `tee` because the folder belongs to root. And the client fetched it by
name. That is the lab's **known good state**: a request from the client to a server, answered. Every
fault on the target is measured against it.
