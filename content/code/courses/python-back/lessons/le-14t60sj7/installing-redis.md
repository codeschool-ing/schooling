---
title: Installing Redis
version: 1
---

Celery puts tasks in a **broker**, a server that holds messages until a worker takes them. It can
use RabbitMQ or Redis; this course uses **Redis**, the in-memory data store that `servers-cache`
installs and studies, which is one install for both uses.

## Three places to have it

| path | what you get | what it costs your computer |
|---|---|---|
| **in your virtual machine** (recommended) | Redis 7 from Ubuntu's archive, as a service | a few megabytes of disk, and a small server in the background of the virtual machine |
| **installed on your own computer** | Homebrew's `redis` on macOS; on Windows there is no native build, and Redis's documentation points to WSL | the same, on the computer you also work on |
| **online** | a Redis that a hosting company runs, often with a free allowance | nothing on your computer; a URL with a password, on someone else's terms |

**The virtual machine is the one to pick**, for the same reasons as PostgreSQL in lesson 4, and it is
the same package `servers-cache` installs. A hosted Redis works with Celery unchanged: the broker URL
below gains a password and a host name, and lesson 15 says where such a URL lives. It was not used for
this course.

## Installing it

In the virtual machine:

```sh
sudo apt update
sudo apt install -y redis-server
```

The package installs the server and `redis-cli`, and starts the service. Check all three:

```
ana@vm:~/agenda$ redis-server --version
Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=d064f9f48c901a92
ana@vm:~/agenda$ systemctl is-active redis-server
active
ana@vm:~/agenda$ redis-cli ping
PONG
```

**`PONG`** is Redis answering on its default port, 6379, on `127.0.0.1` only: Ubuntu's configuration
does not listen on other addresses, which is what a broker on the same machine wants. Then Celery,
with the extra that pulls in the Redis client:

```
ana@vm:~/agenda$ uv add "celery[redis]"
Resolved 35 packages in 280ms
Prepared 16 packages in 2.97s
Installed 16 packages in 7ms
 + amqp==5.4.1
 + billiard==4.3.1
 + celery==5.6.3
 + click-didyoumean==0.3.1
 + click-plugins==1.1.1.2
 + click-repl==0.4.1
 + kombu==5.6.2
 + packaging==26.3
 + prompt-toolkit==3.0.53
 + python-dateutil==3.0.0
 + redis==6.4.0
 + six==1.17.0
 + tzdata==2026.5
 + tzlocal==5.4.5
 + vine==5.1.0
 + wcwidth==0.9.3
```
