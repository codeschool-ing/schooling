---
title: Port 443, and what it costs
version: 1
---

A hotel's guest network, a customer's office, some mobile carriers: plenty of networks let out web
traffic and little else. The home router in the lab was made into one, as root and not shown, and this
is its forwarding chain:

```
ana@homegw:~$ sudo nft list chain ip filter forward
table ip filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		iifname "eth0" tcp dport 443 accept
		iifname "eth0" udp dport 53 accept
	}
}
```

Policy `drop`, with three exceptions: replies to conversations already open, TCP to port 443, and DNS.
**UDP to port 1194 is none of them**, and the client, given eight seconds, got as far as naming the
server:

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 8 openvpn --config client.conf | grep -E "link remote|Initialization"
2026-09-28 18:08:10 UDPv4 link remote: [AF_INET]203.0.113.2:1194
```

No error, no refusal, no `Initialization Sequence Completed`. The packets left the laptop and died at
the home router, which is what a firewall with a `drop` policy does, and the client kept waiting for an
answer. Both files were then changed in two lines each, also not shown: the server to `proto tcp-server`
and `port 443`, the client to `proto tcp-client` and `remote vpn.example.com 443`.

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "TCP connection|Peer Connection|Initialization"
2026-09-28 18:08:20 Attempting to establish TCP connection with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 TCP connection established with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 [vpn.example.com] Peer Connection Initiated with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 Initialization Sequence Completed
```

**Up in the same second.** To the home router this is one more TCP connection to port 443, which it lets
out because it lets out every web page. That is the reason most TLS VPNs can fall back to TCP 443, and
the reason firewalls that are serious about it look further than the port. **Port 443 gets past a
firewall that filters by port, and it does not make the tunnel look like a web page.** The client's
first message is OpenVPN's `HARD_RESET`, as the handshake capture showed over UDP, and not a TLS `Client
Hello`. A firewall that reads what it forwards can tell the difference.

## TCP inside TCP

Over TCP the tunnel works, and it is the worse way to run one, for a reason this lab cannot show: no
link here loses a packet or takes any time. **What goes wrong is two layers of retransmission stacked
on each other.** The laptop's own TCP connections, a download say, now travel inside the tunnel's TCP
connection. When the path loses one packet of the tunnel, the tunnel's TCP stops delivering everything
behind it until the lost one is sent again. The download inside sees its data stall, assumes the loss
is its own, and retransmits too, onto a connection that is already recovering. Each layer backs off, on
timers that were tuned for a link and not for another TCP.

On a clean path nobody notices. On a lossy one, throughput can collapse far below what either layer
would manage alone, which people call **TCP meltdown**. So the usual advice is UDP first, and TCP 443
only where UDP is blocked. Some TLS VPN clients do that on their own, trying DTLS, TLS over UDP, and
falling back to TCP 443 when it fails; this lab ran OpenVPN and did not test any of those.

## The portal in a browser

The other thing sold as an SSL VPN needs no client at all. The person opens `https://` in a browser,
signs in to a portal, and gets a page of links to internal web applications. **There is no tunnel and
no route**: the gateway fetches each internal page on the person's behalf and relays it, a reverse
proxy with a login in front. It works from a machine nobody installed anything on, it reaches only what
the portal publishes, and anything that is not a web application needs a plug-in or a real client. This
was not run in the lab; lesson 5 comes back to per-application access as an alternative to a VPN.
