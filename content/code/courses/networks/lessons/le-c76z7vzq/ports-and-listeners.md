---
title: Who is listening, and on which port
version: 1
---

Lesson 1 section 05 used `ss -tln` to list listening TCP ports. Three more letters make it much more
useful: `-u` adds UDP, `-p` names the program, and `sudo` is needed to see other users' programs. On
the provider's DNS resolver:

```
ana@resolver:~$ sudo ss -tulpn
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                            
udp   UNCONN 0      0          127.0.0.1:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=5))
udp   UNCONN 0      0      198.51.100.53:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=3))
tcp   LISTEN 0      256    198.51.100.53:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=4))
tcp   LISTEN 0      256        127.0.0.1:8953      0.0.0.0:*    users:(("unbound",pid=44351,fd=7))
tcp   LISTEN 0      256        127.0.0.1:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=6))
ana@www:~$ sudo ss -tlpn
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                   
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*    users:(("sshd",pid=44385,fd=3))                          
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=44364,fd=5),("nginx",pid=44363,fd=5))
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=44364,fd=6),("nginx",pid=44363,fd=6))
ana@laptop:~$ grep -wE '^(ssh|domain|http|https|smtp|imaps)' /etc/services
ssh             22/tcp                          # SSH Remote Login Protocol
smtp            25/tcp          mail
domain          53/tcp                          # Domain Name Server
domain          53/udp
http            80/tcp          www             # WorldWideWeb HTTP
https           443/tcp                         # http protocol over TLS/SSL
https           443/udp                         # HTTP/3
domain-s        853/tcp                         # DNS over TLS [RFC7858]
domain-s        853/udp                         # DNS over DTLS [RFC8094]
imaps           993/tcp                         # IMAP over SSL
http-alt        8080/tcp        webcache        # WWW caching service
```

The resolver, `unbound`, holds five sockets. **Port 53 appears twice for each address, once as `udp`
and once as `tcp`**: DNS questions normally travel over UDP, and fall back to TCP when an answer is
too big for one packet. UDP sockets show `UNCONN` rather than `LISTEN`, because UDP has no connections
to listen for; a UDP socket simply receives whatever arrives. Port 8953 on `127.0.0.1` is unbound's
control port, reachable only from the machine itself.

On the web server, `nginx` holds ports 80 and 443 and `sshd` holds 22. nginx appears twice on each
line: a master process that opened the sockets, and a worker that serves the requests.

The numbers are conventions, and `/etc/services` lists them. `https` has a UDP line too: **HTTP/3
runs over UDP**, which section 08 comes back to. A listener on a port that is not its usual one is
always worth a second look; it is how a forgotten test server, or something worse, hides.
