---
title: Network and infrastructure
version: 1
---

The database and the lock were found by `Server-Timing`, because both are inside the
application, where the server's own clock runs. The two causes in this section are outside it,
and the way to find them is the subtraction from the first section: **when the client's time is
much larger than the server's, the difference was spent between them.**

## Forty milliseconds on a kept connection

Every load tool of lessons 4 to 7 keeps its connection open between requests, as a browser does,
and on `app.py` every one of them pays about 40 ms more per request than `curl` does. `measure.py`
opens a fresh connection each time, which is why lesson 8's numbers do not show it. This script
asks for `/health`, the cheapest answer the box office has, five times on one kept connection and
then five times on fresh ones, and prints the client's time beside the server's total:

```python
# boxoffice/keepalive.py
# Five requests for /health on one kept connection, then five on fresh
# connections, each printed with the time the client saw and the time the
# server says it spent (the total in its Server-Timing header).
import http.client, time

def ask(conn):
    start = time.perf_counter()
    conn.request("GET", "/health")
    answer = conn.getresponse()
    answer.read()
    client = (time.perf_counter() - start) * 1000
    server = answer.getheader("Server-Timing").split("total;dur=")[1]
    return f"client {client:5.1f} ms   server {server} ms"

kept = http.client.HTTPConnection("127.0.0.1", 8000)
for i in range(5):
    print("kept connection ", ask(kept))
for i in range(5):
    fresh = http.client.HTTPConnection("127.0.0.1", 8000)
    print("fresh connection", ask(fresh))
    fresh.close()
```

Save it as `~/boxoffice/keepalive.py`. Stop `app_fixed.py` with `Ctrl+C` and start `app.py` again
for a moment, then run it:

```
ana@nft:~/boxoffice$ python3 keepalive.py
kept connection  client   2.9 ms   server 0.5 ms
kept connection  client  43.4 ms   server 0.3 ms
kept connection  client  47.9 ms   server 43.5 ms
kept connection  client  44.0 ms   server 47.6 ms
kept connection  client  43.9 ms   server 44.1 ms
fresh connection client   1.7 ms   server 0.6 ms
fresh connection client   1.0 ms   server 0.4 ms
fresh connection client   0.7 ms   server 0.2 ms
fresh connection client   0.7 ms   server 0.2 ms
fresh connection client   0.8 ms   server 0.2 ms
```

On fresh connections the client sees 0.7 to 1.7 ms. On the kept one, the first request takes 2.9
ms and **every request after it about 44 ms**, while the server said 0.3 ms for the second. The
43 ms nobody accounted for are not in the application. They are in TCP, and the cause is two
reasonable rules meeting:

- `app.py` writes each answer in two pieces, the headers and then the body, because that is how
  Python's `http.server` sends them. **Nagle's algorithm** holds back a small piece of data while
  an earlier one has not yet been acknowledged, so that a program writing a byte at a time does
  not flood the network with tiny packets. So the body waits for the client to acknowledge the
  headers.
- The client delays its acknowledgement, hoping to carry it on a packet of its own soon, which
  saves a packet. On Linux that **delayed acknowledgement** waits at least 40 ms.

Each side waits for the other, and the deadlock breaks when the delay runs out. A fresh connection
escapes it because Linux acknowledges at once at the start of a connection. The fix is to switch
Nagle's algorithm off on the server's socket, the `TCP_NODELAY` option, which is what
`disable_nagle_algorithm = True` in `app_fixed.py` does.

Look at the server's column from the third request on, too: 43.5, 47.6, 44.1 ms. The server was
not working for that time. `app.py` starts its clock when it begins waiting for the next request
on a connection, so on a kept connection its total includes the wait for a client that was itself
waiting for the end of the last answer. **A measurement is only as good as where its clock starts**,
and `app_fixed.py` restarts the clock in `parse_request`, when a request has arrived. Stop
`app.py`, start `app_fixed.py`, and run it again:

```
ana@nft:~/boxoffice$ python3 keepalive.py
kept connection  client   5.5 ms   server 0.2 ms
kept connection  client   0.4 ms   server 0.2 ms
kept connection  client   0.5 ms   server 0.1 ms
kept connection  client   0.3 ms   server 0.1 ms
kept connection  client   0.2 ms   server 0.0 ms
fresh connection client   1.4 ms   server 0.1 ms
fresh connection client   2.3 ms   server 0.1 ms
fresh connection client   2.6 ms   server 0.1 ms
fresh connection client   1.0 ms   server 0.2 ms
fresh connection client   1.1 ms   server 0.1 ms
```

After the first, every kept request takes between 0.2 and 0.5 ms at the client, and the server's column says
0.2 ms or less. That is the number lessons 4 to 7 would have measured on `app_fixed.py`.

## The queue in front of the server

Before the server sees a connection, the operating system has to complete it and put it in a
queue for the program to accept. Its length is set by the program when it starts listening, and
Python's `socketserver`, which `http.server` is built on, asks for **5**. When the queue is full,
the kernel drops the new connection's opening packet, and the client, hearing nothing, tries again
after a second, then after two more, then four. The counter of those drops is
`TcpExtListenOverflows`, and `nstat` prints it: `-n` resets the counters without printing them,
and `-z` prints a counter even when it is zero. With `app.py` running, thirty-two workers:

```
ana@nft:~/boxoffice$ nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows
32 workers, 6.0 s: 3381 requests, 561.3 per second
all          3381    50.6     9.0    15.8    19.2  1035.5  4780.4
#kernel
TcpExtListenOverflows           190                0.0
```

**190 connections were dropped in five seconds**, and the percentiles show the retries the
clients made: a median of 9.0 ms, a p99 of 1035.5 ms, about a second, and a maximum of 4780.4 ms,
a request that was dropped several times over. Those are the one-second outliers of the database
section's run, and the shape is a fingerprint worth knowing: a tail that sits near one second,
or near three, is almost always a connection being retried, not a slow server. In USE terms it is the
**errors** column of the accept queue, and it is invisible in every log the application writes,
because the application never saw those connections.

`app_fixed.py` asks for a queue of 128. With it running:

```
ana@nft:~/boxoffice$ nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows
32 workers, 5.1 s: 3178 requests, 626.2 per second
all          3178    50.5    49.5    65.1    70.8    85.6   115.4
#kernel
TcpExtListenOverflows           0                  0.0
```

No connection dropped, a p99 of 85.6 ms and a maximum of 115.4. The median rose, from 9.0 to
49.5 ms, and that is correct rather than a regression. Before, many of the 32 workers were sitting
out a second waiting to retry, so fewer requests were inside the server and those few were quick.
Now all 32 are inside, and Little's law says 626.2 a second × 0.0505 s is about 32. **A median that
improves because some users are not being served is the same trap as lesson 8's fast errors.**

## Latency and bandwidth

On `127.0.0.1` there is no distance and no wire, so this lesson measures neither of the two
properties that make a real network slow. **Latency** is the time a packet takes to cross, paid
on every round trip: opening a connection costs one, and TLS adds more. `curl -w` shows it as
`time_connect`, which was 0.293 ms here, and which is commonly tens of milliseconds between
continents. **Bandwidth** is how many bytes a second the path carries, and it decides how long a
large answer takes to arrive after its first byte. `curl` reports it as `%{speed_download}`, in
bytes a second, beside `%{size_download}`; on this machine both are meaningless, and neither was
run for this lesson. A load test run on the same machine as the server, as every one in this
course is, measures the application with the network taken out, and that is a condition the
requirement should state, as lesson 1 asked.

## Processors, memory, disk, and the generator

Run thirty-two workers against `app_fixed.py` and look at both programs:

```
ana@nft:~/boxoffice$ python3 measure.py 32 8 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait
  11951 ana       20   0 1399780  29868  11800 S 130.0   0.2   0:11.27 python3 app_fixed.py
  17678 ana       20   0 2320684  19852   9964 S  30.0   0.1   0:00.57 python3 measure.py 32 8
  11951 ana       20   0 1407960  29880  11800 S 116.5   0.2   0:13.60 python3 app_fixed.py
  17678 ana       20   0 2320812  20076   9964 S  23.5   0.1   0:01.04 python3 measure.py 32 8
ana@nft:~/boxoffice$ head -1 load.txt
32 workers, 8.0 s: 5773 requests, 717.3 per second
```

`app_fixed.py` is at 116.5% of a processor in the second snapshot, and the throughput is 717.3
requests a second. That is a little over one processor out of four, and **it is where this server stops**. Python runs the Python code of one thread at a time, so a single Python process tops out
near one processor, with a little more for the time it spends in SQLite and in the kernel. The
next fix would be more processes, not a faster index. `measure.py` is at 23.5%: **the generator
is not the bottleneck**. If its process were near its own ceiling, the test would be measuring
the generator, and the remedy is a second generator, or a more efficient one such as those of
lessons 4 to 7, never a conclusion about the server.

For memory, `free -m` gives the totals:

```
ana@nft:~/boxoffice$ free -m
               total        used        free      shared  buff/cache   available
Mem:           16093        1488        7359          14        7584       14604
Swap:              0           0           0
```

These figures are the computer the transcripts were recorded on, with 16 GB; on your 4 GB machine
the numbers are smaller and the reading is the same. The column that matters is `available`, what
programs can still have without anything being pushed out, and the `Swap` line. Memory saturates
by **swapping**, moving pages to disk, and a machine that swaps under load gets slower by orders
of magnitude; `vmstat`'s `si` and `so` columns count it per second, and they stay at 0 below. The
box office itself is small: `top`'s `RES` column showed about 30 MB for it.

The disk is the last resource, and bookings are what use it, because every commit writes. While
sixteen workers book against `app_fixed.py`:

```
ana@nft:~/boxoffice$ python3 measure.py 16 8 1.0 > load.txt & sleep 2; vmstat 1 4; wait
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
11  0      0 7050516 423864 7331064    0    0  2075 30997 9694   50 46 14 34  5  1  0
 4  0      0 7068544 423864 7331180    0    0     0  7808 22244 37515 43 21 31  4  1  0
 2  0      0 7115428 423864 7331140    0    0     0  9900 18553 30387 42 18 33  5  2  0
 1  0      0 7178920 423864 7331296    0    0     0 10796 18035 31749 35 19 39  5  2  0
```

`vmstat 1 4` prints a line a second; the first is the average since the machine started, so read
the three after it. `bo` is kilobytes written per second, 7808 to 10796 here; `wa` is the share of
time the processors sat waiting for the disk, 4 to 5%; `b` is the number of processes blocked on
it, 0. **The disk is busy and not saturated.** As with `top`'s summary line, these columns cover
the whole recording computer, which was doing other work too.

## Telling them apart

| what you see | where to look |
|---|---|
| server's `Server-Timing` close to the client's time, one part dominant | inside the application: that part |
| throughput flat, latency rising, processors idle | a software resource: a lock, a pool, a queue |
| throughput flat, the server's process using its processors | the code or the database it is waiting on |
| client's time much larger than the server's | between them: the network, TCP, a proxy |
| a tail near 1 s or 3 s | connections dropped and retried |
| the generator's own process at its ceiling | the generator, not the system |
| `si`, `so` or `wa` rising | memory or disk |

The order of the sections in this lesson is the order to look in. **Read the clocks first,
because they are free, and they say which layer before any tool has to say which resource.**
