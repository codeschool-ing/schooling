---
title: Blameless, with owners
version: 1
---

The rule that caused lesson 21's fault was written by somebody. The easy sentence for the record is
"an engineer added a rule that broke path MTU discovery", and it is true, and **it teaches nothing except
to hide the next mistake**. The next mistake is the one you most need to hear about early, from the
person who made it, while it is still small.

A blameless post-mortem asks a different question: **what made the mistake easy to make and hard to
see?** Dropping outbound "destination unreachable" is a hardening step people recommend in good faith,
because it stops a router from telling a scanner which addresses and ports are closed. The lab does not
say why the `hardening` table was added to `hq`, or when, and a real post-mortem would find out by asking
questions like these rather than by guessing:

- Was there a tunnel on `hq` when the rule went in, or did the tunnel arrive later and meet it?
- What did whoever wrote the rule know about what "destination unreachable" carries?
- Which test, run after the change, would have shown the damage, and why was it not part of the change?
- Why did the fault look like an application problem to the people who hit it first?

The record describes decisions with the information available when they were made, and it names rules,
changes and gaps, not people. "The `hardening` rule drops type 3 messages on `hq`'s output, including
fragmentation needed" is a sentence the person who wrote the rule can read, agree with and fix.

**Blameless is not ownerless.** The questions end in action items, and an action item without an owner
is a wish. Each one needs four things: an action somebody can start today, one owner, a date, and **a
test that says it is done**. For lesson 21's case:

| action | owner | done when |
|---|---|---|
| Narrow the `hardening` rule so that fragmentation needed, ICMP type 3 code 4, leaves `hq` | `hq`'s administrator | `ping -M do -s 1400` from `files` prints `Frag needed` instead of silence |
| Make MSS clamping part of every tunnel's standard configuration, not only `wg0`'s | network lead | a SYN through any tunnel carries that tunnel's MTU less 40 |
| Add a large download across each tunnel to monitoring | monitoring owner | an alert fires when `big.bin` stops arriving whole |
| Check the other routers for the same rule | `hq`'s administrator | the list of routers checked is attached to the record |

None of these was carried out in the lab, and the first "done when" is a prediction from lesson 1's
tunnel, where the same ping printed `Frag needed and DF set (mtu = 1480)`. In a real record the owner
column holds a person's name. The lab has one user, `ana`, so here it holds roles, which is the weaker
form: **a role is an owner only if everybody agrees who fills it this week**.

The date column is left out here because the lab has no calendar to set one against, and it is not
optional in a real record.
An action item with no date is done when somebody remembers it, which is after the fault comes back.
