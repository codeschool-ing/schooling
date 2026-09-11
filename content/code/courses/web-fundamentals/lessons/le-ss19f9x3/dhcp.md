---
title: Where the address comes from
version: 1
---

Nobody typed your address. You joined a network and a moment later you had one, along with a mask,
a gateway and somewhere to send name lookups — four settings, none of which you chose.

The machinery that hands them out is **DHCP**, and it is worth a section because most of what goes
wrong with a new connection goes wrong here.

## Four questions in the dark

The awkwardness is that a machine with no address has to ask for one, and asking normally requires
an address. DHCP works around that by shouting, in four steps.

| step | who | what it says |
|---|---|---|
| discover | the new machine | is there anybody here who hands out addresses? |
| offer | the server | yes — how about `192.168.1.24`? |
| request | the new machine | I will take it |
| acknowledge | the server | it is yours, for the next twelve hours |

The first two go to the broadcast address, because neither side has anything more specific to use
yet. The whole exchange takes a few milliseconds and is the reason a device "joins" a network
rather than simply being on it.

## A lease, not a gift

That last step is the one people miss. An address is **leased for a fixed time**, not granted.

Halfway through the lease, the machine asks to renew, and almost always gets the same address back.
If it is switched off for long enough the lease expires, the address returns to the pool, and
something else may take it.

Which explains a whole class of confusion:

- a printer that worked yesterday and cannot be found today — it came back with a different
  address, and whatever was pointing at the old one still is;
- a rule written against a device's address that quietly stops applying;
- a machine that has been off for a week coming back as somebody else's neighbour.

The answer, where it matters, is a **reservation**: the server is told to always give this MAC
address that IP. Which is the practical reason the previous section's number turns up in a router's
settings screen.

## Four things arrive, not one

It is easy to think of DHCP as "getting an address". It is usually four settings, and the other
three are where the interesting failures live.

**The address and the mask** you have met. **The gateway** is the last line of the routing table
from lesson two — where to send everything that is not local. **The DNS server** is where name
lookups go, which is lesson eight.

So a machine can have a perfectly valid address and still be unable to do anything, because the
gateway it was handed is wrong. And it can reach anything by address while every name fails,
because the DNS server it was handed is not answering. Those are different faults with different
causes, and they both look like *the internet is not working*.

## The address that means it failed

One value is worth recognising on sight. If a machine asks and nothing answers, most operating
systems give themselves an address in `169.254.x.x`.

That range is *link-local* — it lets two machines on a wire talk to each other with no server
present, which is occasionally useful. But if you see it on a network that is supposed to have a
router, it means exactly one thing: **nothing answered the DHCP request.** The cable, the Wi-Fi
association, or the server itself.

It is one of the most useful single symptoms in networking, because it points at a specific step
rather than at a vague failure.

## And it trusts whoever answers first

The same property as ARP, for the same reason. A machine takes the first offer it receives, and
nothing verifies that the offering machine has any authority.

So a second DHCP server on a network — set up by mistake, which happens when somebody plugs a home
router into an office wall — starts handing out addresses and a gateway pointing at itself. Half
the machines get the right settings and half get the wrong ones, depending on who answered first.

It is worth knowing because the symptom is bizarre: some devices work perfectly and others do not,
with no pattern by type or location, and every individual machine looks correctly configured.

## Where this leaves you

An address is leased rather than owned, handed over in a four-step exchange that begins with a
broadcast, and it arrives with a mask, a gateway and a DNS server. Leases expire, which is why
addresses move; reservations are how you stop them. `169.254` means nothing answered, and the
first answer is the one believed.

Your machine now has an address, knows what is local, and can find a neighbour's card. The last
question of this lesson is what happens to that private address on its way **out** of the building
— and that is the video.
