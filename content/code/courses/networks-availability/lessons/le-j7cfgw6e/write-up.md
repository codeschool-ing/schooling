---
title: Lesson 21's case, written up
version: 1
---

This is the whole record for lesson 21's black hole, built only from what that lesson's transcripts
printed. It is short on purpose. **A record somebody reads at the start of an incident has to fit on a
screen**, and anything longer goes in an appendix with the full captures.

## Summary

Downloads from `files` at head office to the branch over the WireGuard tunnel stalled at 0 bytes, while
small pages from the same server loaded. Packets over 1420 bytes were dropped at the entrance to `wg0`
on `hq`, and the message that would have told the sender to use smaller ones was dropped by a firewall
rule on `hq`'s own output. **Fixed by clamping the TCP MSS to 1380 on `hq`. The rule is still in place**
and is the first action item.

## Symptom

In the branch's words: the file server's page opens, a download from it never finishes. Measured from the
till:

```
ana@till:~$ curl -sS -m 5 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/
200 16 bytes
ana@till:~$ curl -sS -m 8 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
curl: (28) Operation timed out after 8002 milliseconds with 0 bytes received
000 0 bytes
```

## Timeline

No clock times were recorded, so this timeline has an order and no times, which is itself a finding for
the next incident. In order, as the transcripts show it:

1. `/` from the till: `200 16 bytes`.
2. `big.bin` from the till: 0 bytes, curl gives up after 8002 ms.
3. Capture on `hq`'s office side: 1448-byte segments leave `files`, and none of the nine packets captured
   acknowledges data.
4. From `files`, Don't Fragment pings: `-s 1392` crosses, `-s 1400` is lost with no error.
5. `wg0` on `hq` has `mtu 1420`.
6. `nft list ruleset` on `hq` shows the `hardening` rule dropping destination unreachable on output.
7. MSS clamping to 1380 added on `hq`, both directions through `wg0`.
8. `big.bin` from the till: `200 20000000 bytes`, and the till's SYN reaches the office with `mss 1380`.

## Hypotheses and tests

| | hypothesis | test | result | verdict |
|---|---|---|---|---|
| 1 | the name, the route, the tunnel or the web server is down | `/` from the till | `200 16 bytes` | refuted: all four work |
| 2 | full-size packets are lost on the way to the till | `tcpdump` on `hq`'s office side during the download | 1448-byte segments sent, no data acknowledged in nine packets | supported |
| 3 | the tunnel's MTU is smaller than those packets | Don't Fragment pings from `files`; `ip link show wg0` | 1392 crosses, 1400 lost; `mtu 1420` | confirmed |
| 4 | `hq`'s "fragmentation needed" never reaches `files` | the 1400 ping's statistics; `nft list ruleset` on `hq` | no `+1 errors`; a rule drops destination unreachable on output | confirmed |

## Cause

Two conditions together, neither enough alone. The tunnel carries packets of at most 1420 bytes while
the office network sends 1500. And path MTU discovery, which would normally shrink the sender's packets,
depends on an ICMP message that `hq` builds and then drops on its own output. **The first condition is
normal for any tunnel; the second turns it into a black hole.**

## Fix and verification

Two nftables rules on `hq` rewrite the MSS of every SYN through `wg0` to 1380, the tunnel's MTU less 40
bytes of IP and TCP header. Verified with the test that found the fault:

```
ana@till:~$ curl -sS -m 30 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
200 20000000 bytes
```

## Still open

The fix covers TCP only, and the `hardening` rule still drops every destination unreachable `hq` sends.
The four action items in the previous section are this record's last part: narrow the rule, make
clamping standard on every tunnel, monitor a large transfer, and check the other routers.

## What helped, and what hid it

**The small page working did the most with the least**: one command ruled out four suspects. **The
silence was the hard part**, since nothing on any screen said "too big", and the clue was the absence of `+1
errors` in a statistics line. That is worth a line in the record, because the next person will be
looking at the same silence.
