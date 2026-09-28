---
title: AllowedIPs: the route and the filter
version: 1
---

The name suggests a permission, the addresses a peer is allowed to reach, as if it were a line in a
firewall. **It is a list of the addresses that live behind a peer, and WireGuard reads it in both
directions.** The design calls this cryptokey routing: every address range is tied to exactly one
public key.

Going out, a packet that the kernel has routed into `wg0` is looked up by its destination. The peer
whose `AllowedIPs` contains that address is the one it is encrypted for, and it goes to that peer's
endpoint. Coming in, a packet is decrypted with a peer's session key, and **its source address must be
in that same peer's `AllowedIPs`, or it is dropped**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 320\" role=\"img\" aria-label=\"hq&#x27;s two peers as a table: the branch&#x27;s key n/CGaD63… with AllowedIPs 10.20.0.2/32 and 192.168.20.0/24 and endpoint 198.51.100.2:51820; Ana&#x27;s key FYBqYy68… with 10.20.0.3/32 and no endpoint yet. Going out, a packet in wg0 for 192.168.20.30 is matched by destination to the row containing 192.168.20.0/24, encrypted for n/CGaD63… and sent to 198.51.100.2:51820. Coming in, a packet decrypted with n/CGaD63…&#x27;s key is checked by source against the same row: if the source is in it the packet is delivered, if not it is dropped and nothing is sent back.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hq's peers, from wg0.conf</text><text x=\"28\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">peer (public key)</text><text x=\"234\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllowedIPs</text><text x=\"520\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Endpoint</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n/CGaD63…</text><rect x=\"226\" y=\"50\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"234\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.2/32, 192.168.20.0/24</text><rect x=\"512\" y=\"50\" width=\"228\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.2:51820</text><rect x=\"20\" y=\"84\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FYBqYy68…</text><rect x=\"226\" y=\"84\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"234\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.3/32</text><rect x=\"512\" y=\"84\" width=\"228\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">none yet</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">going out: read by destination</text><rect x=\"20\" y=\"160\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a packet in wg0 for</text><text x=\"115.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M212 183 L236 183\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"240\" y=\"160\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the row that contains it</text><text x=\"355.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.0/24</text><path d=\"M472 183 L496 183\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"500\" y=\"160\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted for n/CGaD63…, sent to</text><text x=\"630.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.2:51820</text><text x=\"20\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">coming in: read by source</text><rect x=\"20\" y=\"260\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decrypted with the key of</text><text x=\"115.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n/CGaD63…</text><path d=\"M212 283 L236 283\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"240\" y=\"260\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is its source in that row?</text><text x=\"355.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M472 283 L496 283\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"500\" y=\"260\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes: delivered. No: dropped,</text><text x=\"630.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and nothing is sent back</text></svg>", "caption": "One list, read twice. The column that picks the key for a packet going out is the column that checks a packet coming in."}
```

The kernel's routing table plays only the first part. It gets packets into `wg0`, and has no idea which
peer they are for:

```
ana@hq:~$ ip route | grep wg0
10.20.0.0/24 dev wg0 proto kernel scope link src 10.20.0.1 
192.168.20.0/24 dev wg0 scope link 
```

The filter is the half that nobody sees until it bites. To show it, `branch`'s entry for `hq` was cut
down, as root and not shown, to `hq`'s tunnel address alone:

```
ana@branch:~$ sudo wg show wg0 allowed-ips
B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=	10.20.0.1/32
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

```

Everything else was intact. `hq` still had its route, the handshake still worked, and the laptop's
ping was encrypted and delivered to `branch`. There it was decrypted, found to come from
`192.168.10.20`, which is not in `10.20.0.1/32`, and dropped. **Nothing printed an error on either
side**: the laptop saw 100% loss, as it did with the wrong GRE key in lesson 1. Putting the office LAN
back into the list brings the till back:

```
ana@branch:~$ sudo wg set wg0 peer B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I= allowed-ips 10.20.0.1/32,192.168.10.0/24
ana@laptop:~$ ping -c 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=0.725 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.725/0.725/0.725/0.000 ms
```

Two consequences are worth more than the mechanism.

**The source address of a packet leaving `wg0` is proof of who sent it.** A packet from `192.168.20.30`
that came out of the tunnel on `hq` was decrypted with `branch`'s key, because no other peer may use
that address. So a firewall rule on `hq` written for `192.168.20.0/24` is a rule about the branch, and
Ana's laptop, allowed `10.20.0.3/32` and nothing else, cannot send a packet claiming to be the till.
That is what WireGuard has in place of user accounts.

**A range belongs to one peer at a time.** Giving `192.168.20.0/24` to a second peer takes it away from
the first, because an outgoing packet has to have exactly one answer to "which key?". Two branches
numbered with the same LAN therefore cannot both hang off `hq`, a problem lesson 5 meets from the other
side.

The list on a laptop is what makes a tunnel split or full. `AllowedIPs = 192.168.10.0/24` sends only
the office through the tunnel; `AllowedIPs = 0.0.0.0/0` sends everything, and lesson 5 captures both.
