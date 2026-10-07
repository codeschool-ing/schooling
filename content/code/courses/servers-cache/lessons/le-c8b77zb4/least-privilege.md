---
title: Least privilege, from the processes down
version: 1
---

Everything so far assumes the programs are correct. This section is about the day one of them is not:
a flaw in the shop's code, or in a library it uses, lets somebody run a command as the shop. **What
they can do next is decided by what the shop was allowed to do**, and that was decided long before.

Each program already runs as its own user, and none of them as root once it has started:

```
ana@web:~$ ps -o user,pid,cmd -C nginx | head -n 3; ps -o user,pid,cmd -C python3
USER         PID CMD
root         177 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data    1647 nginx: worker process
USER         PID CMD
shop          83 /usr/bin/python3 /opt/shop/shop.py
shop          84 /usr/bin/python3 /opt/shop/shop.py
ana@web:~$ sudo -u www-data touch /var/www/ipe/defaced.html
touch: cannot touch '/var/www/ipe/defaced.html': Permission denied
```

Nginx's master keeps root only to open ports below 1024 and read the private key; the workers that
handle every request are `www-data`, and `www-data` cannot write a single file in the site. The shop
runs as `shop`. And nothing that does not have to be reachable from outside is:

```
ana@web:~$ sudo ss -ltn | awk 'NR>1 {print $4}' | sort
0.0.0.0:443
0.0.0.0:80
127.0.0.1:14000
127.0.0.1:15000
127.0.0.1:8001
127.0.0.1:8002
127.0.0.53%lo:53
127.0.0.54:53
```

Only Nginx listens on every address. The shop, Pebble and the local DNS resolver listen on loopback
alone, so the only way to reach the shop from another machine is through Nginx and its rules. **A
firewall adds a second, independent layer** (on Ubuntu, `sudo ufw allow 22,80,443/tcp` and then
`sudo ufw enable`). It was not run on the machine this course was recorded on, whose network is private to it already. On a server with a public address it is the first thing to set up, before
lesson 1's servers are started.

## Fencing the application in with systemd

systemd can take away from a service what its user alone does not: the right to write anywhere but
its own directory, to see other users' homes, to load kernel modules, to gain privileges through a
`setuid` program. `systemd-analyze security` scores how exposed a service is:

```
ana@web:~$ systemd-analyze security shop@1.service --no-pager | tail -n 1
→ Overall exposure level for shop@1.service: 9.2 UNSAFE :-{
ana@web:~$ cat /etc/systemd/system/shop@.service.d/hardening.conf
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/lib/shop
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
SystemCallArchitectures=native
CapabilityBoundingSet=
```

`ProtectSystem=strict` makes the whole filesystem read-only for the service, except the paths named
in `ReadWritePaths`, here the shop's database. `NoNewPrivileges` means no program the shop starts can
ever become more privileged than the shop. The rest close off the kernel, the devices and the kinds
of socket the shop has no use for. A drop-in file in `shop@.service.d/` adds them to the unit without
editing it:

```
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart shop@1 shop@2 && systemctl is-active shop@1 shop@2
active
active
ana@web:~$ systemd-analyze security shop@1.service --no-pager | tail -n 1
→ Overall exposure level for shop@1.service: 3.6 OK :-)
ana@web:~$ curl -s -X PUT -d '{"price_cents": 5290}' https://ipelivros.example/api/books/1 | jq -c '{id, price_cents}'
{"id":1,"price_cents":5290}
```

From 9.2 to 3.6, and the shop still answers and still writes prices to its database. What this buys
is easiest to see with a stronger account than `shop`. The `shop` user cannot write the code it runs,
because the file belongs to root; and under the same two settings, **even root** cannot write outside
the one directory it was given:

```
ana@web:~$ sudo -u shop touch /opt/shop/shop.py
touch: cannot touch '/opt/shop/shop.py': Permission denied
ana@web:~$ sudo systemd-run --wait --pipe -p ProtectSystem=strict -p ReadWritePaths=/var/lib/shop sh -c 'touch /var/lib/shop/ok && echo wrote /var/lib/shop/ok; touch /opt/shop/x' 2>&1 | head -n 3
Running as unit: run-u135.service
wrote /var/lib/shop/ok
touch: cannot touch '/opt/shop/x': Read-only file system
```

`Read-only file system`, for root. Each of these layers assumes the one before it has already failed,
which is what makes them worth having together.

**And one leak this lesson chose to keep:** `X-Served-By` still tells every visitor which copy of the
shop answered. It is useful while learning, and the next lessons read it. On a production site,
`proxy_hide_header X-Served-By;` in the API's location removes it, for the same reason the version
number went in the first section.
