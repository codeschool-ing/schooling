---
title: Why a peer at home is hard to reach
version: 1
---

The peers in the last section sat on the same switch, with addresses each could reach. On the
internet most machines that would be peers sit behind a router doing NAT, and **NAT lets
conversations out and does not let new ones in**. Lesson 11 takes NAT apart; this section only shows
what it does to peer to peer.

In the office lab, r1 joins the office, `10.20.10.0/24`, to the provider, and every office machine
leaves with r1's one public address, `203.0.113.2`. Going out works. pc1 is the client of a web server
outside the office:

```
ana@pc1:~$ curl -s -m 3 http://192.0.2.80/
served by web1
```

(`web1` is one of the two servers behind the load balancer from lesson 1.) Now the other direction.
From the provider's router, isp, a connection is tried to port 8000 at the office's public address,
the way a peer on the internet would try to reach a listener on pc1:

```
root@isp:~# nc -z -v -w 3 203.0.113.2 8000
nc: connect to 203.0.113.2 port 8000 (tcp) failed: Connection refused
```

`Connection refused` is an answer, and it came from r1 itself. The attempt reached `203.0.113.2`,
which is r1's own address. r1 has no program on port 8000 and no rule saying that port belongs to a
machine inside, so its kernel answered with a refusal, and pc1 was never asked. **From outside, the
office is one address with nothing behind it** until somebody configures a way in, which is lesson
11's port forwarding.

The way out works because r1 remembers it. Its connection-tracking table holds pc1's web request:

```
root@r1:~# conntrack -L -p tcp 2>/dev/null | head -3
tcp      6 118 TIME_WAIT src=10.20.10.21 dst=192.0.2.80 sport=59190 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=59190 [ASSURED] mark=0 use=1
```

Read the line in two halves. `src=10.20.10.21 dst=192.0.2.80 sport=59190 dport=80` is the connection
as pc1 sent it. The second half is the reply r1 expects: from `192.0.2.80` port 80, to `203.0.113.2`
port `59190`. A packet arriving that matches the second half is translated back and delivered to pc1.
A packet that matches nothing in the table, like isp's attempt on port 8000, has nowhere inside to
go. (`TIME_WAIT` and `118` say the connection has already closed and the entry has 118 seconds left.)

Now put both peers behind routers like r1. Each can start a conversation out, and neither can receive
one. Programs that need peer to peer through NAT combine three published techniques, and the names
are worth recognising because they turn up in firewall logs and in configuration screens:

- **a relay**: both peers connect out to a server that passes data between them. It works whenever
  both can reach the server, and it makes the conversation client-server again (TURN is the standard
  one);
- **asking a server what the outside sees**: a peer learns from a server the public address and port
  its router gave it (STUN), so it has something to tell the other peer;
- **connecting from both sides at once**, so that each router already has an entry for the
  conversation when the other peer's packet arrives. It gets through many NATs and not through all of
  them, which is why ICE, the procedure that coordinates the three, keeps the relay as the last
  resort.

A video call between two homes is the usual example: it is set up through the provider's servers, and
the sound and picture go straight between the two homes when the routers allow it, through a relay
when they do not.
