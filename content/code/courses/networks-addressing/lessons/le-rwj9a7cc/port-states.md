---
title: What each port is for, and what it is doing
version: 1
---

Two separate things are said about a port in spanning tree, and mixing them up is the usual
confusion. Its **role** is what the election decided it is *for*: a root port, a designated port,
or a blocked one. Its **state** is what it is *doing* right now: blocking, listening, learning,
forwarding, or disabled. A port's role can be decided in a moment, and the state then takes its
time to catch up.

## Roles: one root port per switch, one designated port per cable

Once the root is elected, the other ports get their roles in two passes.

- **Root port.** Every switch except the root picks the one port with the lowest total cost to the
  root. It is how that switch reaches the rest of the tree.
- **Designated port.** On every cable, the two ends compare what they offer, and the end with the
  lower cost to the root becomes the designated port: the one that forwards traffic onto that cable
  and away from the root. **Every port on the root itself is designated**, because nothing is
  closer to the root than the root.
- **Blocked port.** A port that is neither stays blocked. It still listens to BPDUs, which is how it
  will notice when it is needed, and forwards nothing else.

The kernel shows each of `sw3`'s ports with the designated end of its cable:

```
root@sw3:~# ip -d link show p1 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"
state UP
state forwarding
port_id 0x8001
designated_port 32770
designated_bridge 8000.2:6a:dc:93:3b:8a
root@sw3:~# ip -d link show p2 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"
state UP
state forwarding
port_id 0x8002
designated_port 32770
designated_bridge 8000.2:a5:9d:31:2a:8c
```

The first `state UP` is the interface, and the second is the spanning-tree state. On `p1`, the cable
to `sw1`, the designated bridge is `8000.2:6a:dc:93:3b:8a`: `sw1`'s bridge ID, printed with its
leading zeros dropped. The designated end of that cable is on the root, as it must be, so **`p1` is
`sw3`'s root port**, the port number 1 that `root_port:1` named in the previous section.

On `p2`, the cable to `sw2`, the designated bridge is `sw3` itself, `8000.2:a5:9d:31:2a:8c`, and the
designated port `32770` is `0x8002`, `p2`'s own `port_id`. **`sw3`'s `p2` is the designated port for
the `sw2`–`sw3` cable.**

Why `sw3` and not `sw2`? Both are one cable from the root, at a cost of 2, so the cost ties. The tie
goes to the lower bridge ID, and `sw3`'s `02a59d312a8c` is lower than `sw2`'s `02e0779de790`. That
leaves `sw2`'s end of the cable, `p3`, with no role, and it is the port that showed
`state blocking`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The triangle after the election. sw1, bridge ID 8000.026adc933b8a, is the root bridge, and both its ports to the other switches, p2 and p3, are designated. sw2, bridge ID 8000.02e0779de790, reaches the root through p1, its root port. sw3, bridge ID 8000.02a59d312a8c, reaches it through its own p1, also a root port. On the cable between sw2 and sw3, sw3's p2 is designated, because sw3 has the lower bridge ID, and sw2's p3 is blocked. That blocked port is the only one that forwards nothing.\"><path d=\"M360 40 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 254 L170 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 254 L550 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 114 L210 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M400 114 L510 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M230 232 L490 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"298\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"422\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"214\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"506\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"238\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"482\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"368\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"178\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"558\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><rect x=\"320\" y=\"10\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><rect x=\"130\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><rect x=\"510\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><rect x=\"300\" y=\"70\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw1</text><text x=\"360.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.026adc933b8a</text><rect x=\"110\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw2</text><text x=\"170.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.02e0779de790</text><rect x=\"490\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw3</text><text x=\"550.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.02a59d312a8c</text><text x=\"428\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">root bridge</text><text x=\"278\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designated</text><text x=\"440\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designated</text><text x=\"198\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root port</text><text x=\"522\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root port</text><text x=\"482\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designated</text><text x=\"240\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">blocked</text><path d=\"M258 225 L272 239\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M258 239 L272 225\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path></svg>", "caption": "Roles after the election with default priorities. Each switch has one root port, each cable one designated end, and the only port left over, sw2's p3, blocks. The triangle forwards as a line: sw2, sw1, sw3."}
```

## States: how a port gets to forwarding

The original 802.1D has five states, and a port moves through them in one direction:

| state | BPDUs | learns MAC addresses | forwards data |
| --- | --- | --- | --- |
| blocking | received | no | no |
| listening | sent and received | no | no |
| learning | sent and received | yes | no |
| forwarding | sent and received | yes | yes |
| disabled | none | no | no |

**Listening and learning each last one *forward delay*, 15 seconds by default.** Listening gives the
election time to finish across the whole network before the port does anything. Learning fills the
MAC table first, so that when the port starts forwarding it is not flooding every frame to every
port. So a port that has to come into use waits about 30 seconds, which is why `sw1`'s `p3` was in
`listening` just after the cable went in, and why the lab waited 40 seconds before reading the
result.

`disabled` is not a decision of the protocol. It is a port with no signal or one an administrator
switched off. The unplugged `p3` in the first section was `state disabled` beside `NO-CARRIER`, and
the last section of this lesson shows a port put there on purpose.
