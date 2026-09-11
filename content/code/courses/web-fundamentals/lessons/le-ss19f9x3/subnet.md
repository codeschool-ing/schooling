---
title: Deciding what is local
version: 1
---

Beside the address, in every network setting you have ever opened, there is a second number. It is
the **mask**, and it answers one question: *which addresses are on my own wire, and which ones do
I have to hand to the gateway?*

That question is asked for every single packet a machine sends, and it is the first decision in
the routing you met in lesson two.

## The address is two parts, and the mask says where they split

An address is a network part and a host part, stuck together. The network part is the same for
everything on your wire; the host part is what tells two machines on it apart.

The mask says how many bits from the left belong to the network.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"One address split by a mask. Twenty-four bits on the left shaded as the network part, eight on the right as the host part, with a vertical line between them marked slash twenty-four.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">192.168.1.24 / 24</text><rect x=\"24\" y=\"44\" width=\"480\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect><text x=\"264\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the network — 24 bits</text><text x=\"264\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">192.168.1</text><rect x=\"516\" y=\"44\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect><text x=\"606\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the host — 8 bits</text><text x=\"606\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.24</text><text x=\"264\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same for everything on this wire</text><text x=\"606\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what tells them apart</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">two addresses are local to each other when their network parts are identical</text></svg>", "caption": "The mask is not part of the address. It is how the machine holding the address reads it."}
```

Two notations mean exactly the same thing. `255.255.255.0` writes the mask as an address, with a
1 for every network bit; `/24` just says how many there are. The second is called **CIDR**, it is
what you will see almost everywhere now, and it is easier to read once you accept it is a count.

## The arithmetic you will actually do

With `/24`, the first three numbers are the network and the last is the host. So:

- `192.168.1.24` and `192.168.1.99` are **local** to each other — send the frame straight there;
- `192.168.1.24` and `192.168.2.99` are **not** — hand it to the gateway.

That is the entire decision, made per packet, thousands of times a second.

Now the sizes, which is the part people memorise and should not have to:

| mask | network bits | addresses | usable | what it usually is |
|---|---|---|---|---|
| `/24` | 24 | 256 | 254 | one ordinary home or office network |
| `/25` | 25 | 128 | 126 | half of one |
| `/26` | 26 | 64 | 62 | a small segment, a rack |
| `/30` | 30 | 4 | 2 | a link between two routers and nothing else |
| `/16` | 16 | 65,536 | 65,534 | a large company, a cloud network |

**Each bit given to the network halves the range.** That is the only rule; the table is that rule
applied five times. And the *usable* column is always two fewer, because the first address names
the network and the last is broadcast — the two you met in the previous section.

## The same arithmetic, from the other end

There is a second way to read a mask, and it is the one that makes the sizes obvious without
memorising them.

A `/24` leaves 8 bits for the host, and 8 bits count 256 values. A `/25` leaves 7, which counts
128. A `/26` leaves 6, which counts 64. **The host bits are the exponent**, and the table in the
last section is 2 raised to it.

Which means you can answer the two questions that come up in practice without looking anything up:

- *how many machines fit?* — count the host bits, raise two to that, subtract two;
- *how small a mask do I need for 50 machines?* — 6 host bits gives 62 usable, 5 gives 30, so `/26`.

The subtraction of two catches people out for a while and then never again. A range of four
addresses — a `/30`, used for the link between two routers — holds exactly two usable ones, which
is why that size exists at all.

## Why anybody would cut a network up

Splitting one large range into several smaller ones is called subnetting, and it is done for three
reasons that have nothing to do with running out of addresses.

**Broadcast.** Some traffic goes to everything on the wire — including the ARP you will meet two
sections from now. On a network of 65,000 machines that is a great deal of noise arriving at
every one of them. Smaller networks mean less of it.

**Separation.** Traffic between two subnets must pass through a router, and a router is a place
where rules can be applied. Putting the printers, the servers and the guest Wi-Fi on separate
subnets is how a network is given any structure at all.

**Blast radius.** A misbehaving machine floods its own segment, and not the entire building.

## The mistake that looks like a broken network

One symptom is worth carrying away, because it is common and it looks like something else.

A machine with the **right address and the wrong mask** can reach some things and not others, with
no pattern that makes sense. Too narrow a mask and it treats local machines as distant, sending
their traffic to a gateway that may not know how to return it. Too wide and it treats distant
machines as local, shouting onto its own wire for a machine that is not there.

Everything looks configured. The address is correct. It is the second number that is wrong, and
almost nobody checks it first.

## Where this leaves you

The mask splits an address into a network part and a host part, and two machines are local when
their network parts match. `/24` means 24 bits of network and 256 addresses, 254 of them usable,
and every extra bit halves the range.

That decision — local or not — is made on the address. But a frame does not travel by address, as
lesson two was careful to say. It travels by the number burned into a network card, and the next
two sections are what that number is and how a machine discovers its neighbour's.
