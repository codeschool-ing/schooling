---
title: Connection tracking, the memory a stateful firewall has
version: 1
---

**A stateful firewall keeps a table of the conversations it has seen**, and judges a packet by
where it falls in one. Linux calls it connection tracking, `conntrack`. Every packet is first matched
against the table, and a rule can then ask about its **state**:

| state | the packet is |
|---|---|
| `new` | the first of a conversation the table does not know yet |
| `established` | part of a conversation already in the table, in either direction |
| `related` | a new flow that belongs to a known one, such as an ICMP error about it |
| `invalid` | none of those: a reply to nothing, flags that make no sense |

The same policy as before, written statefully:

```
root@fw:~# cat stateful.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept
  }
}
```

**The first rule does the work of every return rule at once.** Anything belonging to a conversation
already allowed passes, in both directions. The third rule decides which conversations may begin:
from the LAN, to `app`, on 8080. Nothing else can start one.

```
root@fw:~# nft -f stateful.nft
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
status: ok
exit 0
ana@db:~$ nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"
exit 1
```

The application answers `laptop`, and the trick from `db` with source port 8080 now fails. Its
first packet is `new`, it came from the servers segment, and no rule lets a conversation start
there.

## The table itself

`conntrack -L` prints what `fw` remembers. `laptop` held one connection open to `app` and had just
closed another:

```
root@fw:~# conntrack -L 2>/dev/null
tcp      6 431999 ESTABLISHED src=192.168.10.20 dst=192.168.20.10 sport=46140 dport=8080 src=192.168.20.10 dst=192.168.10.20 sport=8080 dport=46140 [ASSURED] mark=0 use=1
tcp      6 117 TIME_WAIT src=192.168.10.20 dst=192.168.20.10 sport=49590 dport=8080 src=192.168.20.10 dst=192.168.10.20 sport=8080 dport=49590 [ASSURED] mark=0 use=1
```

Each entry carries **both directions of the conversation**. The first `src=… dst=…` is the packet
as it was first seen; the second is what a reply must look like. `ESTABLISHED` and `TIME_WAIT` are
TCP's own states, and the number before them is how many seconds the entry has left: 431,999 for the
open connection, under two minutes for the closed one. `[ASSURED]` means traffic was seen both ways,
which protects the entry when the table fills up.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"One conntrack entry drawn as two rows. The original direction: from laptop, 192.168.10.20, port P, to app, 192.168.20.10, port 8080. The reply direction: from app port 8080 back to laptop port P. A packet matching either row belongs to the conversation and is established; a packet matching neither is new or invalid.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp  6  431999  ESTABLISHED   [ASSURED]</text><text x=\"36\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">original</text><text x=\"130\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src=192.168.10.20  sport=P      dst=192.168.20.10  dport=8080</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reply</text><text x=\"130\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src=192.168.20.10  sport=8080   dst=192.168.10.20  dport=P</text><text x=\"36\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds left, TCP state, seen both ways</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">A packet matching either row is established. One matching neither is new, or invalid.</text></svg>", "caption": "One entry, both directions. P is the port laptop chose for this connection."}
```

An entry is only created when a rule accepts the `new` packet. **Dropping a packet also means no
memory of it**, so a denied conversation leaves nothing in the table for its replies to match.
