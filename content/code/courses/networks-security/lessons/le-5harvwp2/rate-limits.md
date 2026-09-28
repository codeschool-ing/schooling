---
title: Rate limits at the proxy
version: 1
---

A request can be perfectly well formed and still be a problem when it arrives two hundred times a
second from one address. Guessing passwords, scraping a catalogue and an overeager script all look
like that. **A rate limit caps how fast one client may ask**, and the proxy is the natural place for
it because it sees every request before the application spends anything on it.

nginx does it in two lines, one at the top of the file and one in the location:

```
root@www:~# grep -n "limit_req" /etc/nginx/sites-enabled/shop
2:limit_req_zone $binary_remote_addr zone=perip:10m rate=5r/s;
3:limit_req_status 429;
23:        limit_req zone=perip burst=10 nodelay;
```

`limit_req_zone` keys the limit on the client's address, keeps its counters in 10 MB of shared
memory, and allows **5 requests per second**. `burst=10` lets a client get ten requests ahead of that
rate before anything is refused, and `nodelay` serves those ten at once instead of spacing them out.
`limit_req_status 429` answers with the status that means *too many requests*; nginx's default is
`503`, which tells the client the server is broken when it is not.

Thirty requests from `remote`, as fast as `curl` can send them:

```
ana@remote:~$ for i in $(seq 30); do curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/; done | sort | uniq -c
     15 200
     15 429
```

**Sixteen were served and fourteen refused**: the burst of ten, plus what the rate refilled while the
loop ran. Meanwhile the limit was only ever about `remote`:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
root@www:~# grep -c "limiting requests" /var/log/nginx/error.log; grep -m1 "limiting requests" /var/log/nginx/error.log | cut -d" " -f3-
15
[error] 32145#32145: *41 limiting requests, excess: 10.715 by zone "perip", client: 203.0.113.50, server: www.example.com, request: "GET / HTTP/1.1", host: "www.example.com"
```

`laptop` was served during the burst because its address has a counter of its own, and three
seconds later `remote` was served again. Every refusal is in the error log with the client's
address, which is what somebody reads afterwards to decide whether it was a script or a mistake.

## What a per-address limit cannot do

A limit keyed on the address assumes one address is one client. Two things break that:

- **Many clients behind one address.** A whole office behind one NAT shares one counter, and a busy
  one hits the limit together. Limits are set for the busiest legitimate address, not the average.
- **One client behind many addresses.** Traffic spread over thousands of machines stays under every
  per-address limit. That is a distributed attack, and lesson 6 treats it separately, because it has
  to be absorbed before it reaches the proxy.
