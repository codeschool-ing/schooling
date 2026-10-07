---
title: Bringing it up, and a handshake of two packets
version: 1
---

`wg-quick` reads the file and does the rest: it creates the interface, loads the keys, adds the address
and turns every `AllowedIPs` range into a route. On the kernel these transcripts were recorded on, it
also shows what happens when the kernel has no WireGuard in it:

```
ana@hq:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.1/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 192.168.20.0/24 dev wg0
```

The first command fails with `Unknown device type`: the kernel has no WireGuard module. **So
`wg-quick` falls back to `wireguard-go`**, the same protocol written as an ordinary program by the same
author. From outside it behaves identically, only slower.

**The banner under it is wrong about this machine.** It says the kernel has first-class support for
WireGuard, one line after the kernel refused to create the device. WireGuard has been part of Linux
since version 5.6 and the banner is written for that ordinary case; the kernel these transcripts were
recorded on was built without it. On a normal server, and on your Ubuntu, the first command succeeds
and none of the rest appears.

The last four lines are the file being applied. **`mtu 1420` is 1500 minus 80**, the room WireGuard
keeps for its own headers when the outer packet is IPv6, the larger of the two cases. And
`192.168.20.0/24 dev wg0` is the branch LAN from `AllowedIPs`, now a route.

Bring `branch` up the same way, with `sudo wg-quick up wg0` in its own shell. Nothing has crossed the
network yet. **WireGuard sends nothing until there is something to send**, so
the handshake happens when the laptop pings the till. `tshark` was started first, on the ISP's link
towards the branch, and printed its four packets when it stopped:

```
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=2.85 ms
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.944 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.944/1.898/2.853/0.954 ms
ana@isp:~$ tshark -n -i eth1 -c 4 -f "udp port 51820"
Capturing on 'eth1'
4 packets captured
    1 0.000000000  203.0.113.2 → 198.51.100.2 WireGuard 190 Handshake Initiation, sender=0x2881E370
    2 0.000755650 198.51.100.2 → 203.0.113.2  WireGuard 134 Handshake Response, sender=0x05725C3D, receiver=0x2881E370
    3 0.001210443  203.0.113.2 → 198.51.100.2 WireGuard 170 Transport Data, receiver=0x05725C3D, counter=0, datalen=96
    4 0.001769928 198.51.100.2 → 203.0.113.2  WireGuard 170 Transport Data, receiver=0x2881E370, counter=0, datalen=96
```

Four packets, and **the first two are the whole handshake**. `hq` sends a Handshake Initiation of 190
bytes, `branch` answers with a Handshake Response of 134, and from then on both have session keys.
Packets 3 and 4 are the ping and its reply, as `Transport Data`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"A sequence between hq at 203.0.113.2 and branch at 198.51.100.2, from the tshark capture. At 0.000000000 seconds hq sends a Handshake Initiation of 190 bytes; at 0.000755650 branch sends a Handshake Response of 134 bytes. From there both have session keys. At 0.001210443 hq sends Transport Data of 170 bytes, the ping, and at 0.001769928 branch sends Transport Data of 170 bytes, the reply.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"180\" y=\"14\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"250.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"520\" y=\"14\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"590.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M250 56 L250 318\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M590 56 L590 318\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time (s)</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.000000000</text><path d=\"M254 100 L586 100\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  Handshake Initiation</text><text x=\"420.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">190 bytes</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.000755650</text><path d=\"M586 160 L254 160\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  Handshake Response</text><text x=\"420.0\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">134 bytes</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.001210443</text><path d=\"M254 240 L586 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  Transport Data</text><text x=\"420.0\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">170 bytes</text><text x=\"238\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the ping</text><text x=\"20\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.001769928</text><path d=\"M586 296 L254 296\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  Transport Data</text><text x=\"420.0\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">170 bytes</text><text x=\"238\" y=\"296\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the reply</text><path d=\"M190 200 L650 200\" stroke=\"var(--scan)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"660\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">handshake</text><text x=\"660\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">session keys</text><text x=\"660\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exist from</text><text x=\"660\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this point on</text><text x=\"660\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">data</text></svg>", "caption": "The four packets of the tshark capture, in order. Two packets agree the keys, and the third already carries the laptop's ping."}
```

Each side chose a random index for the session, `sender=0x2881E370` for `hq` and `sender=0x05725C3D`
for `branch`, and every data packet names the receiver's index. A receiver finds the session by that
number, not by the address the packet came from, and the section on roaming shows why that matters.
`counter=0` marks the first data packet in each direction. The counter goes up by one per packet and a
receiver refuses a number it has already seen, so a recorded packet cannot be played back later.

The sizes add up. A data packet is 170 bytes on the wire for an 84-byte ping. That is 14 of Ethernet,
20 of outer IP, 8 of UDP and 16 of WireGuard header, then the ping padded to 96 bytes, the `datalen=96`,
and 16 of authentication tag. The first reply took 2.85 ms and the second 0.944 ms, because the first one
waited for the handshake; with no delay on any link, both are one computer talking to itself. **The
first ping was not lost**: WireGuard holds a packet while its session is being agreed.

`wg show` is the interface's state:

```
ana@hq:~$ sudo wg show
interface: wg0
  public key: B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=
  private key: (hidden)
  listening port: 51820

peer: n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=
  endpoint: 198.51.100.2:51820
  allowed ips: 10.20.0.2/32, 192.168.20.0/24
  latest handshake: 1 second ago
  transfer: 348 B received, 404 B sent

peer: FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=
  allowed ips: 10.20.0.3/32
```

The branch peer has an endpoint, a handshake a second old and byte counts that match the capture.
**404 B sent is 148 + 128 + 128**, the initiation's UDP payload and two data packets, and 348 B received
is 92 + 128 + 128. The peer at home has only its allowed IPs. It has never sent anything, so `hq` has no
endpoint for it and no handshake.

That is the ordinary state of a peer nobody is using. **There is no connection to be up or down, only a
handshake that is recent or is not**, and while traffic flows a new one is made every two minutes, with
fresh keys.
