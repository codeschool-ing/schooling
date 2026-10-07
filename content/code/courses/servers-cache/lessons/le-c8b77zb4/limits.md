---
title: Limits on how fast and how slow
version: 1
---

A server that answers everything as fast as it is asked can be made to spend all of its capacity on
one client. Two kinds of limit protect it: on how **often** a client may ask, and on how **slowly** a
client may talk.

## Rate limiting

```conf
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_status 429;
client_header_timeout 5s;
client_body_timeout   5s;
```

The first line declares a zone: ten megabytes of shared memory that count requests per client
address, at ten per second. It is declared in `http { }` and used in a location, with how much of a
burst to tolerate:

```
ana@web:~$ sudo sed -i 's|        limit_except GET HEAD PUT { deny all; }|        limit_except GET HEAD PUT { deny all; }\n        limit_req zone=api burst=20 nodelay;|' /etc/nginx/sites-available/ipelivros && grep -n 'limit_' /etc/nginx/sites-available/ipelivros
27:        limit_except GET HEAD PUT { deny all; }
28:        limit_req zone=api burst=20 nodelay;
ana@web:~$ for i in $(seq 60); do curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo; done | sort | uniq -c
     42 200
     18 429
```

Sixty requests sent as fast as one `curl` after another can go: 42 answered, 18 refused with
`429 Too Many Requests`. The arithmetic is the **token bucket**: the bucket holds 20 extra requests
(`burst=20`), `nodelay` serves those at once instead of spacing them out, and it refills at ten a second
for as long as the loop ran. Nginx logs each refusal:

```
ana@web:~$ grep -c "limiting requests" /var/log/nginx/ipelivros.error.log; grep "limiting requests" /var/log/nginx/ipelivros.error.log | tail -n 1 | cut -c 1-130
18
2026/10/07 00:50:18 [error] 1648#1648: *108 limiting requests, excess: 20.340 by zone "api", client: 127.0.0.1, server: ipelivros.
ana@web:~$ sleep 2; curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo
200
```

and two seconds later the bucket has refilled and the same client is served again. Nginx's own default
for a refusal is `503`; `limit_req_status 429` makes it the code that means "you, slow down", which
well-behaved clients and their retry logic understand.

**Choose the rate from what a real client does, not from what the server can survive.** A person
browsing the bookshop makes a few API calls a second at most; a script copying the whole catalogue
makes hundreds. A limit on a login endpoint is the strongest case, measured in a handful a minute,
because it is what makes guessing passwords slow.

## Slow clients

The opposite attack is to open many connections and send each request one byte at a time, holding a
connection for minutes while sending almost nothing. Nginx's event loop makes each such connection
cheap, and still not free. `client_header_timeout` and `client_body_timeout` decide how long Nginx
waits between two pieces of a request; the default is sixty seconds, and the lines above make it five.
A request with its last header line never sent:

```
ana@web:~$ time (exec 3<>/dev/tcp/127.0.0.1/80; printf 'GET / HTTP/1.1\r\nHost: ipelivros.example\r\n' >&3; cat <&3)

real	0m5.006s
user	0m0.002s
sys	0m0.000s
ana@web:~$ sudo grep -h '" 408 ' /var/log/nginx/*.log | tail -n 1
127.0.0.1 - - [07/Oct/2026:00:50:25 -0300] "GET / HTTP/1.1" 408 0 "-" "-"
```

Five seconds and the connection is closed, with `408 Request Timeout` written to the log and nothing
sent back.
