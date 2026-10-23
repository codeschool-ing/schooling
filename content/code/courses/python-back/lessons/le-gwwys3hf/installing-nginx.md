---
title: Installing nginx
version: 1
---

Gunicorn and Uvicorn should not face the internet themselves. A **reverse proxy** stands in front: it
terminates TLS, serves static files from disk, adds headers, limits request sizes, and passes the
rest to the application on `127.0.0.1`. This course uses **nginx**, the one `servers-cache` teaches in
depth.

## Three places to have it

| path | what you get | what it costs your computer |
|---|---|---|
| **in your virtual machine** (recommended) | nginx 1.24 from Ubuntu's archive, as a service | a few megabytes, and a server on ports 80 and 443 of the virtual machine |
| **installed on your own computer** | Homebrew's `nginx` on macOS; nginx.org's Windows build, which its own documentation calls a beta | the same, on the computer you also work on, where ports 80 and 443 may be taken |
| **online** | a hosting platform's load balancer, which does this job without a configuration file | nothing; and the files below become the platform's settings |

**The virtual machine is the one to pick**: the configuration below names Ubuntu's paths, and it is
the same package `servers-cache` installs.

## Installing it

In the virtual machine:

```sh
sudo apt update
sudo apt install -y nginx
```

The package starts nginx with a default site, a welcome page on port 80:

```
ana@vm:~/agenda$ nginx -v
nginx version: nginx/1.24.0 (Ubuntu)
ana@vm:~/agenda$ systemctl is-active nginx
active
ana@vm:~/agenda$ curl -s http://127.0.0.1/ | grep -o "<title>.*</title>"
<title>Welcome to nginx!</title>
```
