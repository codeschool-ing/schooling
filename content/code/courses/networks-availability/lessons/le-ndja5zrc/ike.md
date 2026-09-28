---
title: "IKEv2: four messages before the first packet"
version: 1
---

Somebody configuring their first IPsec connection usually assumes the pre-shared key encrypts the
traffic. **It does not: it only proves who is at the other end.** The traffic keys are made fresh at
every negotiation, by a Diffie-Hellman exchange, and they never cross the network. The negotiation is
IKE, Internet Key Exchange, here in version 2, on UDP port 500.

## The configuration

`hq` runs strongSwan, whose IPsec configuration is one file, `/etc/swanctl/swanctl.conf`. `sudo cat`
printed it, and here it is cut into its pieces:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  offices {\n    version = 2\n    local_addrs = 203.0.113.2\n    remote_addrs = 198.51.100.2\n    mobike = no", "note": "One connection, `offices`, in IKEv2, between the two routers' public addresses. `mobike = no` turns off the extension that lets a peer change address mid-connection; with it on, strongSwan moves IKE to port 4500 as soon as the first exchange is done, even with no NAT in the way, and this lesson wants port 500 to stay port 500 until the section on NAT."}, {"code": "    proposals = aes256-sha256-modp2048", "note": "The algorithms for the IKE connection itself, not for the traffic: AES with a 256-bit key to encrypt, SHA-256 for integrity and for deriving keys, and Diffie-Hellman group MODP 2048 to agree on a secret. The other side has to accept at least one proposal, or nothing starts."}, {"code": "    local {\n      auth = psk\n      id = hq.example.com\n    }\n    remote {\n      auth = psk\n      id = branch.example.com\n    }", "note": "Who each side is and how it proves it. `auth = psk` means with a pre-shared key; the `id` values are names, and each side checks that the other presented the name it expects. They do not have to resolve in DNS."}, {"code": "    children {\n      lans {\n        local_ts = 192.168.10.0/24\n        remote_ts = 192.168.20.0/24\n        esp_proposals = aes256gcm16\n        start_action = trap\n      }\n    }", "note": "The tunnel itself, a CHILD SA called `lans`. The two `_ts` lines are the traffic selectors, the networks it joins, and must mirror the other side's. `esp_proposals` names the traffic's algorithm, AES-GCM with a 256-bit key. `start_action = trap` waits for the first packet that needs the tunnel."}, {"code": "  }\n}", "note": "Closing the connection. What follows is a separate block that `swanctl` loads into the daemon's store of secrets."}, {"code": "secrets {\n  ike-offices {\n    id-1 = hq.example.com\n    id-2 = branch.example.com\n    secret = \"Tide-Lantern-Orbit-7294-Quill\"\n  }\n}", "note": "The pre-shared key, and the two identities it is valid between. The lab's secret is printed here because it is the lab's; on a real router this block is the one part of the file nobody pastes into a ticket."}]}
```

`branch` has the mirror image. `swanctl --load-all` hands the file to the running daemon, `charon`, and
`--list-conns` shows what the daemon understood:

```
ana@hq:~$ sudo swanctl --load-all
loaded ike secret 'ike-offices'
no authorities found, 0 unloaded
no pools found, 0 unloaded
loaded connection 'offices'
successfully loaded 1 connections, 0 unloaded
ana@hq:~$ sudo swanctl --list-conns
offices: IKEv2, no reauthentication, rekeying every 14400s
  local:  203.0.113.2
  remote: 198.51.100.2
  local pre-shared key authentication:
    id: hq.example.com
  remote pre-shared key authentication:
    id: branch.example.com
  lans: TUNNEL, rekeying every 3600s
    local:  192.168.10.0/24
    remote: 192.168.20.0/24
```

`no authorities found` and `no pools found` are not errors: this connection uses no certificates and
hands out no addresses. The file set no lifetimes, so these are strongSwan's defaults: **the IKE
connection is renegotiated every 14400 seconds, four hours, and the tunnel's keys every 3600.**

## The first packet pays for the negotiation

With `start_action = trap`, nothing is negotiated when the file is loaded. The first packet between the
two networks sets the negotiation off. The laptop pinged the till while the ISP's router captured UDP
ports 500 and 4500:

```
ana@laptop:~$ ping -c 3 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=1.64 ms
64 bytes from 192.168.20.30: icmp_seq=3 ttl=62 time=1.14 ms

--- 192.168.20.30 ping statistics ---
3 packets transmitted, 2 received, 33.3333% packet loss, time 2033ms
rtt min/avg/max/mdev = 1.139/1.390/1.642/0.251 ms
ana@isp:~$ sudo tcpdump -n -t -i eth0 -c 4 udp port 500 or udp port 4500
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 203.0.113.2.500 > 198.51.100.2.500: isakmp: parent_sa ikev2_init[I]
IP 198.51.100.2.500 > 203.0.113.2.500: isakmp: parent_sa ikev2_init[R]
IP 203.0.113.2.500 > 198.51.100.2.500: isakmp: child_sa  ikev2_auth[I]
IP 198.51.100.2.500 > 203.0.113.2.500: isakmp: child_sa  ikev2_auth[R]
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

**`icmp_seq=1` never came back.** It triggered the negotiation and was dropped while it ran; the two
after it found the tunnel ready. The ISP saw four packets: an `ikev2_init` from `hq` and its reply, then
an `ikev2_auth` and its reply. A health check that sends one ping reports a trapped tunnel down every
time the tunnel starts.

`tshark`, Wireshark's engine on the command line, which lesson 11 uses at length, names the messages.
This is a second run, after the connection was torn down, and it lost its first ping the same way:

```
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.947 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 1 received, 50% packet loss, time 1029ms
rtt min/avg/max/mdev = 0.947/0.947/0.947/0.000 ms
ana@isp:~$ tshark -n -i eth0 -c 4 -f "udp port 500"
Capturing on 'eth0'
4 packets captured
    1 0.000000000  203.0.113.2 → 198.51.100.2 ISAKMP 506 IKE_SA_INIT MID=00 Initiator Request
    2 0.001103213 198.51.100.2 → 203.0.113.2  ISAKMP 514 IKE_SA_INIT MID=00 Responder Response
    3 0.004374601  203.0.113.2 → 198.51.100.2 ISAKMP 314 IKE_AUTH MID=01 Initiator Request
    4 0.007878151 198.51.100.2 → 203.0.113.2  ISAKMP 266 IKE_AUTH MID=01 Responder Response
```

The columns are the packet's number, its time in seconds, source, destination, protocol, frame length
and message. The negotiation took **7.9 milliseconds**, on a lab where every link is one computer talking
to itself. Across a real internet each of the two exchanges costs a round trip.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"A sequence between hq at 203.0.113.2 and branch at 198.51.100.2. First, IKE_SA_INIT from hq, 464 bytes, carrying SA, KE, No and two NAT detection notifications, and branch&#x27;s IKE_SA_INIT response, 472 bytes, with the same payloads. These go in clear: offers, Diffie-Hellman values and nonces; afterwards both sides compute the same secret and no key has crossed the wire. Then IKE_AUTH from hq, 272 bytes, with IDi, AUTH, SA, TSi and TSr, and the response, 224 bytes, with IDr, AUTH, SA, TSi and TSr, both encrypted. Last, ESP in both directions carrying the laptop&#x27;s traffic, with SPIs 9ab696f9 in and 4ad97b9d out.\"><defs><marker id=\"ike-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"110.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"540\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"610.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M110 52 L110 372\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M610 52 L610 372\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M110 82 L610 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">IKE_SA_INIT</text><text x=\"360.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SA KE No N(NATD_S_IP) N(NATD_D_IP)</text><text x=\"622\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">464 bytes</text><path d=\"M610 132 L110 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">IKE_SA_INIT</text><text x=\"360.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SA KE No N(NATD_S_IP) N(NATD_D_IP)</text><text x=\"98\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">472 bytes</text><path d=\"M110 222 L610 222\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">IKE_AUTH</text><text x=\"360.0\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">IDi AUTH SA TSi TSr</text><text x=\"622\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">272 bytes</text><path d=\"M610 272 L110 272\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">IKE_AUTH</text><text x=\"360.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">IDr AUTH SA TSi TSr</text><text x=\"98\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">224 bytes</text><text x=\"360.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in clear: offers, Diffie-Hellman values, nonces</text><rect x=\"130\" y=\"172\" width=\"460\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">both compute the same secret; no key crossed the wire</text><text x=\"360.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypted: who each side is, the proof, the networks</text><path d=\"M110 334 L610 334\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\" marker-start=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP, protocol 50: the laptop's traffic</text><text x=\"360.0\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SPIs 9ab696f9_i 4ad97b9d_o</text></svg>", "caption": "The four messages of IKEv2, with the payloads and sizes strongSwan logged for swanctl --initiate. The second exchange is already encrypted with keys derived from the first."}
```

**IKE_SA_INIT goes in clear, and IKE_AUTH is already encrypted.** The first exchange carries each side's
offer of algorithms, its Diffie-Hellman public value and a random nonce. From the two public values both
routers compute the same secret, which nobody watching can, and every later key is derived from it. The
second exchange, `MID=01`, is encrypted with those keys. It carries the identities, the proof made with
the pre-shared key, and the networks to join, so the ISP never sees the name `hq.example.com`.

That exchange builds two things. The IKE SA is the control connection between the routers, and the
CHILD SA is the tunnel the traffic uses; each is rekeyed on its own clock, the 14400 and 3600 seconds
above. IKEv1 called them "phase 1" and "phase 2", and people still do.
