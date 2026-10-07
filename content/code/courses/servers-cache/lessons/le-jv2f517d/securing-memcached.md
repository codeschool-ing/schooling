---
title: Keeping Memcached private
version: 1
---

**Memcached trusts whoever reaches its port.** The text protocol has no user and no password unless one
is switched on, so anyone who can connect can read every key they can name, overwrite any of them and
empty the whole cache with `flush_all`. The defence is that nobody but the application can connect:

```
ana@web:~$ printf 'stats settings\r\n' | nc -q1 127.0.0.1 11211 | grep -E ' (tcpport|udpport|inter|auth_enabled_ascii|item_size_max) '
STAT tcpport 11211
STAT udpport 0
STAT inter 127.0.0.1
STAT auth_enabled_ascii no
STAT item_size_max 1048576
ana@web:~$ sudo ss -ltnup | grep -E 'Local|11211' | sed 's/ *$//'
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      1024       127.0.0.1:11211      0.0.0.0:*    users:(("memcached",pid=1769,fd=26))
```

Ubuntu's settings are the safe ones: TCP on 127.0.0.1 only, and **UDP switched off**, `udpport 0`. UDP
has been off by default since version 1.5.6, after open Memcached servers on the internet were used in
2018 to flood third parties with replies to small forged requests, each reply many thousands of times
the size of the request. A Memcached that must serve other machines listens on a private address,
behind a firewall that admits only the application's servers, and keeps UDP off.

The text protocol can also ask for a password, read from a file. Memcached's own help still marks the
option experimental:

```
ana@web:~$ echo 'shop:Ipe-2026-cache-only' | sudo tee /etc/memcached-auth >/dev/null && sudo chown memcache: /etc/memcached-auth && sudo chmod 600 /etc/memcached-auth
ana@web:~$ echo '-Y /etc/memcached-auth' | sudo tee -a /etc/memcached.conf && sudo systemctl restart memcached
-Y /etc/memcached-auth
ana@web:~$ printf 'get book:7\r\n' | nc -q1 127.0.0.1 11211
CLIENT_ERROR unauthenticated
ana@web:~$ printf 'set auth 0 0 24\r\nshop Ipe-2026-cache-only\r\nset book:7 0 0 1\r\n1\r\nget book:7\r\n' | nc -q1 127.0.0.1 11211
STORED
STORED
VALUE book:7 0 1
1
END
```

With `-Y`, a connection must first send `set auth` with a user and a password from the file as its
data; before that, every command is refused as `unauthenticated`. **The password crosses the network
in clear text**, so it keeps out a neighbour on a private network who connects by mistake, and does not
stop one who can read the traffic. That needs TLS, `-Z`, which Ubuntu's build includes. And the restart
that switched the password on emptied the cache again, which is easy to forget the first time it
happens in production.
