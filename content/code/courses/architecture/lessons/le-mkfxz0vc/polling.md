---
title: Polling and long polling
version: 1
---

**Polling** asks whether there is anything newer than the last event it has seen. Before anything has
happened, and after the warehouse marks order o-1 as paid:

```
ana@vm:~/lab/live$ curl -s "localhost:8001/poll?since=0"; echo
[]
ana@vm:~/lab/live$ curl -s -X POST localhost:8001/publish -d "o-1 paid"
a: published
ana@vm:~/lab/live$ curl -s "localhost:8001/poll?since=0"; echo
["o-1 paid"]
```

The first question got nothing, and so will most. A page that polls every two seconds sends 1,800
requests an hour per open tab, and if the order changes three times in that hour, 1,797 of them were
wasted, each a full HTTP request with headers, cookies and a trip through every layer of the shop. It
is still a fine answer for **slow-changing data with few watchers**, a back-office dashboard refreshed
every minute, because it needs nothing from the infrastructure that plain HTTP does not.

**Long polling** asks the same question and lets the server wait. If there is nothing newer, the server
holds the request open until there is, or for 25 seconds, and answers then. Ask for anything after event
1, and have the warehouse mark the order packed two seconds later:

```
ana@vm:~/lab/live$ (sleep 2; curl -s -X POST localhost:8001/publish -d "o-1 packed" > /dev/null) & time curl -s "localhost:8001/long-poll?since=1"; echo
["o-1 packed"]
real	0m2.019s
user	0m0.004s
sys	0m0.019s
```

The request was answered **2.0 seconds** after it was sent, the moment the event arrived, not at the next
poll. The browser then asks again at once, and the cycle repeats. It costs one held request per waiting
client and about one request per event, and it works through every proxy that allows a request to take
25 seconds. It was how browser chat worked before the alternatives below, and it is still the fallback
in libraries such as Socket.IO when nothing better gets through.
