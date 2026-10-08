---
title: iperf3, and what a speed test measures
version: 1
---

A ping says a path is there; it says nothing about how much the path carries. **iperf3 measures
throughput between two machines you control**: a server that listens, on port 5201 unless told
otherwise, and a client that sends as fast as the path allows for a set time. For these runs `hq`'s link
to the ISP was shaped to 20 Mbit/s, the way lessons 18 and 20 did it,
`sudo tc qdisc add dev eth1 root tbf rate 20mbit burst 32kb latency 50ms` on `hq`, and web1 was the
server, the `iperf3 -s` that `netlab.sh` starts on every web server:

```
ana@web1:~$ ss -tlnp | grep 5201
LISTEN 0      4096         0.0.0.0:5201       0.0.0.0:*          
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 57774 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  3.12 MBytes  26.2 Mbits/sec  154   14.1 KBytes       
[  5]   1.00-2.00   sec  2.12 MBytes  17.8 Mbits/sec    0   17.0 KBytes       
[  5]   2.00-3.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
[  5]   3.00-4.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
[  5]   4.00-5.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-5.00   sec  12.0 MBytes  20.1 Mbits/sec  154             sender
[  5]   0.00-5.01   sec  11.4 MBytes  19.1 Mbits/sec                  receiver

iperf Done.
```

The first second shows 26.2 Mbit/s and **154 retransmissions**: TCP finding the limit, sending faster
than the shaper passes until packets were dropped. From then on it holds at 17.8 to 18.9 with none. The
summary has two lines, and **the receiver's is the one to quote**: 19.1 Mbit/s is what arrived, where
20.1 is what the sender pushed. The gap to 20 is partly headers, which the shaper counts and iperf3 does
not.

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -R | tail -n 4
[  5]   0.00-5.00   sec  1.93 GBytes  3.31 Gbits/sec  1888             sender
[  5]   0.00-5.00   sec  1.93 GBytes  3.31 Gbits/sec                  receiver

iperf Done.
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -P 4 | tail -n 4
[SUM]   0.00-5.00   sec  12.4 MBytes  20.8 Mbits/sec  819             sender
[SUM]   0.00-5.03   sec  11.2 MBytes  18.7 Mbits/sec                  receiver

iperf Done.
```

`-R` reverses the direction: the server sends and the laptop receives. **3.31 Gbit/s, over a hundred and
sixty times the upload.** The shaper sits on what leaves `hq` towards the ISP, so the download was
limited only by one computer copying packets between its own namespaces. Real access links are often
asymmetric by design: many cable and fibre plans sell several times more download than upload, and **a
test in one direction says nothing about the other**.

`-P 4` runs four streams at once, and together they make 20.8 Mbit/s sent and 18.7 received, the same
20 as one stream. Parallel streams help when a single TCP connection is held back by its own window over
a long path; **against a shaper, which caps the total, they only split it**.

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -u -b 10M | tail -n 4
[  5]   0.00-5.00   sec  5.96 MBytes  10.0 Mbits/sec  0.000 ms  0/4316 (0%)  sender
[  5]   0.00-5.00   sec  5.96 MBytes  10.0 Mbits/sec  0.031 ms  0/4316 (0%)  receiver

iperf Done.
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -u -b 30M | tail -n 4
[  5]   0.00-5.00   sec  17.9 MBytes  30.0 Mbits/sec  0.000 ms  0/12947 (0%)  sender
[  5]   0.00-5.06   sec  11.8 MBytes  19.5 Mbits/sec  0.469 ms  4432/12945 (34%)  receiver

iperf Done.
```

With `-u` iperf3 sends UDP at the rate `-b` asks for, and UDP does not back off. At 10 Mbit/s all 4316
datagrams arrived, with 0.031 ms of jitter. At 30 Mbit/s the sender sent 30.0, the receiver got 19.5, and
**4432 of 12945 datagrams were lost, 34%**. The excess is dropped at the bottleneck, and the jitter rose
to 0.469 ms because the datagrams that survived waited in the shaper's queue. That is a video call on a
full link: nothing slows down, pieces go missing and the rest arrive unevenly.

## A public speed test

A speed test in a browser is the same measurement against a server somebody else runs. None was run for
this lesson, because the lab has no way out to the internet, but the reasons its number differs from the
contract follow from the runs above:

- It measures the whole path, including your Wi-Fi, which is the bottleneck in many homes and which
  lesson 6 showed is shared airtime.
- It measures to one server, usually close to your provider, so it says little about a site across
  an ocean.
- It counts data, and the contract counts the line, headers included, so even a perfect line tests a
  few per cent under its rate.
- It usually opens several streams and discards the first seconds, which hides exactly the ramp-up
  the first line of the lab's run showed.

For a complaint to a provider, a speed test is a start. **For a claim about a link you run, iperf3 between
two machines at its ends measures that link and nothing else.**
