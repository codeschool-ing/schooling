---
title: Timeouts, and the three gateway errors
version: 1
---

The shop has an endpoint that takes as long as it is told to, and five seconds is fine by default:

```
ana@web:~$ time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'
200

real	0m5.008s
user	0m0.000s
sys	0m0.007s
```

Nginx waits up to sixty seconds for the application to start answering, which is the default of
`proxy_read_timeout`. Sixty seconds is far longer than any person waits for a page, and a request
that takes that long is holding a connection, a worker's attention and a thread of the application
for a minute. Lower it to three seconds, for the API only, and ask again:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_read_timeout 3s;|' /etc/nginx/sites-available/ipelivros && grep -A2 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://shop;
        proxy_read_timeout 3s;
ana@web:~$ time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'
504

real	0m6.016s
user	0m0.003s
sys	0m0.006s
```

`504 Gateway Timeout`, as expected. **But it took six seconds, not three**, and the log says why:

```
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.error.log | sed -E 's/ \[error\].*(upstream timed out).*(upstream: "[^"]*").*/ \1, \2/'
2026/10/07 00:26:27 upstream timed out, upstream: "http://127.0.0.1:8001/api/slow?s=5"
2026/10/07 00:26:30 upstream timed out, upstream: "http://127.0.0.1:8002/api/slow?s=5"
```

Nginx gave the first member three seconds, gave up, and **tried the request again on the other
member**, which gave it three more: the same `proxy_next_upstream` that rescued every request in the
previous section. For a dead member that is exactly right. For a member that is merely slow it is
twice the waiting and twice the load, sent to an application that is already struggling, and every
member of a group of ten would get its turn. Two settings bound it:

```conf
proxy_next_upstream_tries 2;      # at most this many members per request
proxy_next_upstream_timeout 5s;   # and at most this long, all attempts together
```

Nginx never retries a request that is not **idempotent**, a `POST` for example, unless told to with
`non_idempotent`, because sending a payment twice is worse than failing it once.

## 502, 503 and 504

Three status codes say "the server in front is fine and the one behind is not", and they mean
different things:

| code | what Nginx is saying | where to look |
|---|---|---|
| `502 Bad Gateway` | the application did not answer properly: refused the connection, closed it, or sent something that is not HTTP | is it running? its own logs |
| `503 Service Unavailable` | nobody is available on purpose: a limit was hit or maintenance is on | Nginx's limits (lesson 4) |
| `504 Gateway Timeout` | the application accepted the request and did not answer in time | what the application is waiting on |

The three timeouts that produce a `504` or a `502` each measure something different:
`proxy_connect_timeout` is how long to wait for the connection itself (60 seconds by default, and
rarely more than one is needed on a local network), `proxy_read_timeout` the gap between two reads
of the response, and `proxy_send_timeout` the gap between two writes of the request. None of them is
a limit on the total time of a request; a response that trickles a byte every fifty seconds never
times out.

**A timeout in front should be shorter than the patience of whatever is behind the client**, and
longer than the slowest request the application is meant to serve. The second half is the one that
gets forgotten: a report that takes forty seconds to build needs its own `location` with its own,
longer, timeout.
