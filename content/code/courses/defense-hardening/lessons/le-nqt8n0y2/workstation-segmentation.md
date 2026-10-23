---
title: The administrator's own workstation
version: 1
---

**Everything in this lesson trusts `admin`.** It holds the key, it is the only machine `jump` accepts,
and in a real firm it would hold the certificate for the day. So the last question is what `admin`
itself does all day, and the uncomfortable answer in most offices is: everything. The administrator
reads mail on it, opens attachments, browses vendor documentation, and then logs in to the servers
from the same session.

That is the gap every tidy diagram of a bastion leaves. **A jump server protects the servers from
every machine except the one that is allowed to use it**, and if the administrator's own workstation
is compromised, the attacker uses the bastion exactly as designed.

## A workstation for administration only

The answer has a name in Microsoft's documentation, the **privileged access workstation** (PAW): a
machine, or a separate virtual machine on the administrator's computer, used for administration and
for nothing else. No mail client, no general web browsing, no documents from outside; a short list
of allowed programs; and the only machine whose address the bastion's firewall names. The person
keeps an ordinary workstation for everything else, and the two never share a key.

In the lab, `admin` plays that role and `desk` plays the ordinary workstation, and the rules you wrote
already treat them differently. What the lab does not show is the discipline that keeps them
different, because that is not a configuration: it is a decision that reading mail on `admin` is not
allowed, written down and checked.

## Tiers

Larger organisations generalise the same idea into **tiers**, a model Microsoft documented for
Active Directory and has since folded into its "enterprise access model". Tier 0 is what controls
identity for everybody, the domain controllers and the certificate authority; tier 1 is the servers;
tier 2 is the workstations. The rule is that **credentials only ever flow downwards**: a tier 0
administrator never logs in to a tier 2 workstation, because the moment they do, whoever controls
that workstation can capture what they typed. The jump server and the PAW are how the rule is made
practical rather than merely stated.

The SSH certificate authority of the last section is tier 0 in that model: the most protected key
in this lesson, kept offline, and signing from a machine that does nothing else.

## Windows: one password per machine

One Windows control belongs here because it removes a path this lesson's rules would not see. Windows
machines have a built-in local Administrator account, and for years the habit was to give it the same
password on every machine, set once in the image. Somebody who learnt it on one laptop could then log
in to all of them. **Windows LAPS** (Local Administrator Password Solution) gives each machine its own
random local administrator password, rotates it on a schedule, and stores it in Active Directory or
Microsoft Entra ID where only named people may read it, with every read logged. It was not run for
this course; this paragraph is from Microsoft's documentation. The Linux counterpart in this lab is
what lesson 1 did: no shared root password, no second root, and administrators who log in as
themselves.
