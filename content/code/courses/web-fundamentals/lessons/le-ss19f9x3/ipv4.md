---
title: Reading an address
version: 1
---

An IPv4 address is four numbers separated by dots: `198.51.100.4`. Every one of them is between 0
and 255, and the reason is worth thirty seconds because it explains everything else in this
lesson.

## Four bytes, written for people

The address is really a single number, thirty-two bits long. Nobody can read thirty-two bits, so
it is written as four groups of eight — four bytes — and eight bits count from 0 to 255.

That is the whole of the notation. `256.0.0.1` is not a strict address written oddly; it is not an
address at all, the way a date of the 32nd is not a date.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"One address shown twice. Above, thirty-two bits in four groups of eight. Below, the same value written as four decimal numbers separated by dots, each aligned under its group of bits.\"><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one number, thirty-two bits long</text><rect x=\"24\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"102\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000110</text><rect x=\"196\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"274\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00110011</text><rect x=\"368\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"446\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">01100100</text><rect x=\"540\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"618\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00000100</text><text x=\"102\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">198</text><text x=\"274\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">51</text><text x=\"446\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">100</text><text x=\"618\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">4</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">eight bits count from 0 to 255, which is where the ceiling on each number comes from</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the dots are for you — nothing on the network sees them</text></svg>", "caption": "The dots are punctuation added for people. To every machine this is one thirty-two-bit number."}
```

Thirty-two bits gives about **four and a quarter billion** possible addresses. That sounded
limitless when the number was chosen, and it is the reason two of the later sections in this
lesson exist.

## Yours is probably not yours

Open your network settings and you will very likely see an address starting with `192.168.`, or
`10.`, or something in the `172.16`–`172.31` range.

Those three ranges are **private**. They are set aside deliberately, they are not unique in the
world, and nothing on the internet will route to them. Millions of houses use `192.168.1.10` at
this moment, and there is no conflict, because no packet carrying that destination ever leaves a
local network.

| range | how big | where you meet it |
|---|---|---|
| `10.0.0.0` – `10.255.255.255` | 16.7 million | companies, cloud networks, larger sites |
| `172.16.0.0` – `172.31.255.255` | 1 million | containers and virtual machines, often |
| `192.168.0.0` – `192.168.255.255` | 65 thousand | almost every home router ever sold |

So a machine at home has a **private** address that identifies it on your network, and shares a
single **public** address with everything else in the building. The video at the end of this
lesson is about the machinery that joins the two.

## Why the notation survives being awkward

Four numbers with dots is a strange way to write a thirty-two-bit value, and it has outlived
several attempts to replace it. It is worth a moment because the reason explains the next section.

The split into four bytes lines up, roughly, with how addresses are **handed out**. Large blocks
are allocated on byte boundaries — a whole first number, or a whole first two — so a person reading
`198.51.x.x` can tell at a glance that the first two numbers are somebody's allocation and the last
two are theirs to arrange. That was truer in the 1980s than it is now, and the habit of reading an
address left to right, most general first, is still exactly right.

It is the same shape as a phone number or a postcode: the left is where, the right is which. What
changed is that the boundary stopped falling on a dot, and that is what the mask in the next
section is for.

## Three addresses that are not machines

A few values mean something other than "a particular computer", and they turn up often enough to
be worth recognising.

`127.0.0.1` is **loopback** — this machine, talking to itself. It never reaches a network card at
all; the operating system loops it straight back. It is what `localhost` resolves to, and it is
why a development server on your laptop is reachable from your laptop and from nowhere else.

The **first address of a range** names the network itself rather than anything in it. The **last**
is the broadcast address: everything on this network at once. Neither can be given to a machine,
which is why a range of 256 addresses holds 254 usable ones, and that arithmetic is the next
section.

And `0.0.0.0` means, depending on where you meet it, *no address yet* or *every address on this
machine*. A server "listening on `0.0.0.0`" is listening on all of them.

## The addresses ran out

Four billion addresses and about eight billion people, most of them carrying several connected
devices. The arithmetic stopped working in the 1990s, and the last large blocks were handed out
around 2011.

Three things happened in response, and each is a section of this lesson or the next:

- **private addresses and NAT**, so a household needs one public address rather than twenty;
- **IPv6**, which is a bigger number and the actual answer;
- **a market**, where blocks of IPv4 addresses are now bought and sold for real money.

The third one is not a technology and is worth knowing anyway, because it explains why a cloud
provider charges for a public address that used to be free.

## Where this leaves you

An IPv4 address is thirty-two bits written as four numbers of 0 to 255. The one your machine shows
you is probably private — unique on your network and meaningless outside it — and is not the
address the rest of the world sees you as. A few values are reserved for the machine itself, the
network itself, and everything at once.

What none of that tells you yet is **which addresses count as local**. That is a second number,
it is beside the address in every network setting you have ever seen, and it is the next section.
