---
title: Standing access, and the alternative
version: 1
---

**Lesson 9's assignments are standing access: from the moment one is made, the principal holds the
role every second of every day until somebody removes it.** For Reader on a testing subscription
that is fine. For Owner on production it means the most powerful credential in the company is
switched on at three in the morning on a Sunday, while its holder sleeps, in a browser that has a
dozen other tabs open. A stolen session, a phishing page or a mistyped command run in the wrong
terminal all find that power waiting.

The wrong fix is the one people reach for first: remove the role, and add it back by hand when
somebody needs it. It works for a week. Then the person who adds roles back is on holiday, the
incident is now, the role is added "just for today" and never removed, and the company has standing
access again with no record of why.

**Privileged Identity Management**, PIM, is the feature of Microsoft Entra ID that makes the
alternative routine. It is described here from Microsoft's documentation, and **nothing in this
section was run**: PIM is a service of a real tenant, and needs a licence, Microsoft Entra ID P2 or
Microsoft Entra ID Governance, for the people it covers.

## Eligible and active

PIM adds one word to a role assignment: its **type**. Microsoft's documentation defines two:

- **an active assignment** gives the role now, with nothing to do first. It is lesson 9's
  assignment, with a name;
- **an eligible assignment** gives nothing yet. It gives the right to **activate** the role: to ask
  for it, prove who you are, say why, and then hold it for a limited time.

**There is no difference in what the role allows once it is active.** An Owner who activated an
eligible assignment is exactly as powerful, for those hours, as one with a standing assignment. What
changes is the number of hours, and the fact that each of them was asked for, by name, with a
reason, and written down.

## Permanent and time-bound

Each type also has a **duration**, which is a different question from how long an activation lasts:

| | permanent | time-bound |
|---|---|---|
| **eligible** | may activate at any time, for as long as the assignment exists | may activate only between a start and an end date |
| **active** | holds the role always: standing access | holds the role between a start and an end date |

**Time-bound eligibility is the shape to aim for.** `ana` is eligible for Owner on `rg-shop-prod`
for six months, and in those six months activates it for a few hours when the work needs it. When
the six months end, the eligibility ends with them, and renewing it is a decision somebody makes
again, rather than a role nobody remembers granting. A permanent active assignment is the
exception, kept for the identities that cannot ask: the emergency accounts of lesson 11, and
workload identities, which have no person to answer a prompt.

## What PIM covers

PIM manages three kinds of role, and they are worth keeping apart because the first two live in
different places:

- Azure resource roles: lesson 9's roles, Owner, Contributor and the rest, at the scope of a
  management group, a subscription, a resource group or a resource. They are judged by Resource
  Manager;
- Microsoft Entra roles: the directory's own roles, such as Global Administrator, User
  Administrator and Privileged Role Administrator. They govern the tenant, not Azure's resources,
  and lesson 6 met them;
- groups: membership of a group, or ownership of it, made eligible. A group that holds several
  roles becomes a single thing to activate.

**One Entra role reaches into Azure on its own, and it is worth knowing by name.** A Global
Administrator can switch on *Access management for Azure resources* in the tenant's properties, and
from then on holds User Access Administrator at the root scope, `/`: every subscription in every
management group, with the power to grant itself any role there. Microsoft documents it as the way
back in when nobody else can manage a subscription. It is also a door, so it is switched off again
as soon as the work is done, and an activation of Global Administrator through PIM is the natural
moment to notice that it was used.
