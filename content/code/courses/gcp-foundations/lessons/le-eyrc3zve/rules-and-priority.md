---
title: A rule, and the order rules are read in
version: 1
---

**A firewall rule belongs to one network and says, for one direction, which traffic to allow or deny to
which machines.** It is global, like the network, and it is enforced at each machine's interface rather than
at a box in the path: there is no firewall appliance to size, and two machines in the same subnet are
filtered from each other exactly as from the internet.

A rule is made of:

| part | what it says | the planner's example |
|---|---|---|
| **direction** | `INGRESS`, traffic arriving at the machine, or `EGRESS`, leaving it | ingress |
| **priority** | 0 to 65535; **the lower number is read first**; 1000 if nothing is said | 1000 |
| **action** | `allow` or `deny` | allow |
| **protocol and ports** | `tcp`, `udp`, `icmp`, and for the first two a list of ports | `tcp` 5432 |
| **sources** (ingress) or **destinations** (egress) | address ranges, or for ingress the tags or service accounts of other machines in the network | machines running as `web` |
| **targets** | which machines the rule applies to: all of them, those with a tag, or those running as a service account | machines running as `db` |

**Rules are stateful.** A rule that lets a connection in lets its replies out, and one that lets a connection
out lets its replies in; nobody writes a rule for the return half.

## Which rule decides

For each packet, Google takes the rules that match it and **the one with the lowest priority number
decides**. Two rules at the same priority with opposite actions are settled in one direction only: **deny
wins**. A rule's priority is therefore not decoration. It is the only thing that orders a list in which the
order is the meaning.

Under every network's own rules sit two that are always there, at priority 65535, the last possible:

- **an implied deny of all ingress**: anything no rule allows in is refused;
- **an implied allow of all egress**: anything no rule denies out is let through.

They cannot be deleted, only overridden by a rule with a lower number. So a new custom mode network, with no
rules at all, accepts no connection from anywhere, including from its own other machines, and lets every
machine reach out. The default network of lesson 15 is different only because it is made with four rules at
priority 65534: one allowing all traffic between its own machines, and three allowing SSH, RDP and ping from
anywhere. **Those three are the reason the planner does not use it.**

A little traffic is outside the rules altogether. A machine always reaches the metadata server at
`169.254.169.254`, which is where its service account's tokens come from, lesson 8; and Google blocks
outgoing connections to port 25 on external addresses, whatever a rule says, because a cloud machine sending
mail directly is mostly spam.

## Rules above the network

Rules on a network are not the only layer. **Firewall policies** hold rules too, and can be attached to the
organisation or a folder, lesson 2's tree, as well as to a network. Policies on the tree are evaluated
**before** the network's own rules, and one of their actions is to hand the decision down to the next level.
That is how the planner's security team keeps a rule, such as no SSH from the internet into production, that
no project's administrator can override with a priority 0 of their own. The rest of this lesson is about the
network's own rules, which are what every project writes.
