---
title: Refused or filtered
version: 1
---

"The connection failed" covers two very different situations, and the capture tells them apart in
the first two seconds. **A refused connection is an answer. A filtered one is a silence.**

In both transcripts below the capture ran in a second terminal, started before `curl`; it comes
second because it was printed when it finished.

Nothing listens on port 81 of `web1`:

```
ana@laptop:~$ curl -sS http://192.0.2.21:81/
curl: (7) Failed to connect to 192.0.2.21 port 81 after 0 ms: Couldn't connect to server
ana@laptop:~$ tshark -n -i eth0 -c 2 -f "host 192.0.2.21 and tcp port 81"
Capturing on 'eth0'
2 packets captured
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 37486 → 81 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1552613313 TSecr=0 WS=1024
    2 0.000072428   192.0.2.21 → 192.168.10.20 TCP 54 81 → 37486 [RST, ACK] Seq=1 Ack=1 Win=0 Len=0
```

The laptop sent a SYN, and **72 microseconds later `web1`'s own kernel answered with RST, ACK**: there
is a machine at this address, it received the SYN, and nothing is listening on that port. `curl` reported `Couldn't connect to server` `after 0 ms`. A refused connection is
fast, and it proves the network path works all the way to the host.

Port 8080 on `web1` is closed differently: a firewall rule on `web1` drops anything sent to it, without
a word. Add the rule on `web1`:

```sh
sudo nft add table ip filter
sudo nft add chain ip filter input '{ type filter hook input priority 0; }'
sudo nft add rule ip filter input tcp dport 8080 drop
```

Then the same test, against 8080:

```
ana@laptop:~$ curl -sS --max-time 5 http://192.0.2.21:8080/
curl: (28) Connection timed out after 5002 milliseconds
ana@laptop:~$ tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 8080"
Capturing on 'eth0'
3 packets captured
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344973941 TSecr=0 WS=1024
    2 1.021559067 192.168.10.20 → 192.0.2.21   TCP 74 [TCP Retransmission] 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344974963 TSecr=0 WS=1024
    3 2.045518527 192.168.10.20 → 192.0.2.21   TCP 74 [TCP Retransmission] 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344975987 TSecr=0 WS=1024
```

**No answer at all, so the laptop tried again**: the same SYN, marked `[TCP Retransmission]` by
Wireshark, one second after the first and again one second after that. The capture stopped at three
packets; the laptop kept trying until `curl` gave up at 5002 milliseconds, the five seconds
`--max-time 5` allowed. Without that limit `curl` would have waited much longer, and so would the
person in front of it.

| | refused | filtered |
|---|---|---|
| on the wire | SYN, then RST from the host | SYN, then the same SYN again |
| how fast | at once | after the client's own timeout |
| `curl` says | `Couldn't connect to server` | `Connection timed out` |
| what it proves | the host is up, the port is closed | something dropped the SYN, or its answer |

**The second column does not say where the packet died.** From the client, silence looks the same in four cases: a firewall on the server dropped the SYN, a firewall on the path dropped it, the server is switched off, or the SYN-ACK was lost on the way back. The capture narrows it to "no answer arrived
here"; capturing on the other end, as lesson 12 did on `web1`, is what says whether the SYN arrived.
And a firewall can be told to reject instead of drop, answering with a reset of its own, in which
case a filtered port looks refused. Nothing in this course's network is set up that way.
