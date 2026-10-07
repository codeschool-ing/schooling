---
title: NAT traversal, and a laptop at home
version: 1
---

`remote` is a laptop at home, `192.168.1.50`, behind a home router, `homegw`, that shares one public
address, `198.51.100.77`, among everything in the house. **ESP cannot cross that router as it is,
because ESP has no ports.** A router sharing one address tells conversations apart by port number, as
lesson 11 of `networks-addressing` showed, and an ESP packet gives it nothing to go on.

IPsec's answer is **NAT traversal**: detect the NAT during the first exchange, then carry IKE and ESP
alike in UDP on port 4500. `hq` gets a second connection, `home`, that hands out addresses from
`10.30.0.0/24`. Add it at the end of `hq`'s `/etc/swanctl/swanctl.conf`, after what is already there:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  home {\n    version = 2\n    local_addrs = 203.0.113.2\n    pools = homes", "note": "A second connection on `hq`, `home`, added at the end of the same file. It names only `hq`'s own address: the laptop may arrive from any address, which is the point of remote access. `pools = homes` says where its address comes from."}, {"code": "    local {\n      auth = psk\n      id = hq.example.com\n    }\n    remote {\n      auth = psk\n      id = ana@example.com\n    }", "note": "`hq` proves itself as before; the other side is a person now, `ana@example.com`, not a router."}, {"code": "    children {\n      office {\n        local_ts = 192.168.10.0/24\n        esp_proposals = aes256gcm16\n      }\n    }\n  }\n}", "note": "Only `hq`'s side of the tunnel is named, the office network. The far side is whatever address the pool hands out."}, {"code": "pools {\n  homes {\n    addrs = 10.30.0.0/24\n  }\n}", "note": "The pool: one address per laptop, from `10.30.0.0/24`, a range no office and no home here uses."}, {"code": "secrets {\n  ike-ana {\n    id-1 = hq.example.com\n    id-2 = ana@example.com\n    secret = \"Harbour-Violet-Candle-3381\"\n  }\n}", "note": "Ana's own secret. In a real company each person would have one, or a certificate, which the end of this section comes back to."}]}
```

On `remote`, the laptop, `/etc/swanctl/swanctl.conf` is new, and asks for an address of its own with
`vips = 0.0.0.0`:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  office {\n    version = 2\n    remote_addrs = 203.0.113.2\n    vips = 0.0.0.0", "note": "The laptop's side. It knows where the office is, `remote_addrs`, and not where it is itself. `vips = 0.0.0.0` asks the office for an address."}, {"code": "    local {\n      auth = psk\n      id = ana@example.com\n    }\n    remote {\n      auth = psk\n      id = hq.example.com\n    }", "note": "The same two identities as `hq`'s `home` connection, the other way round."}, {"code": "    children {\n      office {\n        remote_ts = 192.168.10.0/24\n        esp_proposals = aes256gcm16\n      }\n    }\n  }\n}", "note": "The tunnel carries what goes to the office network, and nothing else: the rest of Ana's traffic still leaves through her home router. Lesson 5 calls that split tunnelling."}, {"code": "secrets {\n  ike-ana {\n    id-1 = hq.example.com\n    id-2 = ana@example.com\n    secret = \"Harbour-Violet-Candle-3381\"\n  }\n}", "note": "The same secret as on `hq`."}]}
```

Start `charon` on `remote` as on the routers, with `sudo setsid /usr/lib/ipsec/charon >/dev/null 2>&1 &`,
then run `sudo swanctl --load-all` on `hq` and on `remote`. The laptop started the connection, and the
log was filtered down to the lines that matter:

```
ana@remote:~$ sudo swanctl --initiate --child office | grep -E "NAT|sending|received|virtual|established"
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 192.168.1.50[500] to 203.0.113.2[500] (972 bytes)
[NET] received packet: from 203.0.113.2[500] to 192.168.1.50[500] (280 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[IKE] local host is behind NAT, sending keep alives
[NET] sending packet: from 192.168.1.50[4500] to 203.0.113.2[4500] (304 bytes)
[NET] received packet: from 203.0.113.2[4500] to 192.168.1.50[4500] (256 bytes)
[IKE] installing new virtual IP 10.30.0.1
[IKE] IKE_SA office[1] established between 192.168.1.50[ana@example.com]...203.0.113.2[hq.example.com]
[IKE] CHILD_SA office{1} established with SPIs 8d6d0dca_i 0d6d6c89_o and TS 10.30.0.1/32 === 192.168.10.0/24
ana@isp:~$ sudo tcpdump -n -t -i eth1 -c 6 udp and host 198.51.100.77
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 198.51.100.77.500 > 203.0.113.2.500: isakmp: parent_sa ikev2_init[I]
IP 203.0.113.2.500 > 198.51.100.77.500: isakmp: parent_sa ikev2_init[R]
IP 198.51.100.77.4500 > 203.0.113.2.4500: NONESP-encap: isakmp: child_sa  ikev2_auth[I]
IP 203.0.113.2.4500 > 198.51.100.77.4500: NONESP-encap: isakmp: child_sa  ikev2_auth[R]
IP 198.51.100.77.4500 > 203.0.113.2.4500: UDP-encap: ESP(spi=0x0d6d6c89,seq=0x1), length 120
IP 203.0.113.2.4500 > 198.51.100.77.4500: UDP-encap: ESP(spi=0x8d6d0dca,seq=0x1), length 120
6 packets captured
6 packets received by filter
0 packets dropped by kernel
```

Each side hashes the addresses and ports it believes the packet carried and sends the hashes as
`N(NATD_S_IP)` and `N(NATD_D_IP)`. `remote` hashed `192.168.1.50`, while `hq` saw the packet arrive from
`198.51.100.77`, as the ISP's capture shows. The hashes did not match, and **both sides concluded `local
host is behind NAT` before a single key was agreed.** The first exchange ran on port 500 and the second
on 4500.

IKE and ESP now share port 4500, so the receiver has to tell them apart. An IKE message there starts
with four zero bytes, shown as `NONESP-encap`, and ESP starts with its SPI, which is never zero, shown as
`UDP-encap: ESP`. The keep alives in the log are there because a home router forgets a UDP conversation
that stays silent, and a forgotten one would cut the tunnel from the office's side.

The first request was 972 bytes, against 464 for the offices: neither side named proposals for this
connection, so `remote` offered strongSwan's whole default list. Then the laptop reached the file
server:

```
ana@remote:~$ ping -c 2 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=0.668 ms
64 bytes from 192.168.10.10: icmp_seq=2 ttl=63 time=0.829 ms

--- 192.168.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1013ms
rtt min/avg/max/mdev = 0.668/0.748/0.829/0.080 ms
ana@hq:~$ sudo swanctl --list-sas --ike home
home: #6, ESTABLISHED, IKEv2, b02568a07bd2d4ff_i a5fd5cdcbf0d6f7c_r*
  local  'hq.example.com' @ 203.0.113.2[4500]
  remote 'ana@example.com' @ 198.51.100.77[4500] [10.30.0.1]
  AES_CBC-128/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/ECP_256
  established 2s ago, rekeying in 13644s
  office: #9, reqid 2, INSTALLED, TUNNEL-in-UDP, ESP:AES_GCM_16-256
    installed 2s ago, rekeying in 3260s, expires in 3958s
    in  0d6d6c89,    252 bytes,     3 packets,     0s ago
    out 8d6d0dca,    252 bytes,     3 packets,     0s ago
    local  192.168.10.0/24
    remote 10.30.0.1/32
```

**`hq` knows the laptop by the home router's address, `198.51.100.77[4500]`, and by the address it
handed out, `10.30.0.1`.** The mode is `TUNNEL-in-UDP`, and the `*` is on `_r` this time, because `hq`
answered. `252 bytes, 3 packets` is three 84-byte pings: one sent while the capture ran and the two
above. The reply had `ttl=63`, because `files` sent it with 64 and `hq` routed it once; the home router
only ever saw the outer packet.

The selectors are `10.30.0.1/32` and `192.168.10.0/24`. **The laptop enters the office with the address
the office gave it, never with its home address**, so `hq` needs no route to a `192.168.1.0/24` that
thousands of homes use. Lesson 5 shows what happens when a home network and an office network collide
anyway.

## Pre-shared keys or certificates

A pre-shared key suits two routers: one long, random secret, typed at both ends. It does not suit
people. **A key shared by fifty people cannot be changed without changing it for all fifty**, and
whoever leaves the company keeps it.

| | pre-shared key | certificates | EAP inside IKEv2 |
|---|---|---|---|
| what each side holds | the same secret | its own private key, signed by an authority the other trusts | the gateway a certificate, the person a login |
| removing one peer | change the secret everywhere it is shared | revoke that one certificate | disable that one account |
| fits | two routers | routers, and managed laptops | people, with the company's directory and a second factor |

Certificates are lesson 6 of `networks`; in `swanctl.conf` the change is `auth = pubkey` and a
certificate where the secret was. EAP travels inside IKE_AUTH, so the gateway proves itself with a
certificate and the person with a login and a second factor from the company's directory. Lesson 5 puts
that kind of remote access beside site-to-site.
