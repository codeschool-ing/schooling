---
title: What changes when the data centre is an API
version: 1
---

**On premises, the infrastructure is a place, and changing it means getting into the place. In the
cloud, the infrastructure is an API on the internet, and changing it means holding a key.** Most of
what is different about defending a cloud follows from that one swap.

The common wrong picture runs the other way: that the cloud is safer because somebody else guards
the building, or riskier because the servers are not yours. Both are about the building, and the
building is the part that stopped mattering. The provider's guards are good. What they guard is not
where cloud incidents start.

## Six things that move

**1. The way in to the controls is public.** A data centre's management network sits behind a door,
a badge reader and a firewall. AWS's management interface is `https://` addresses anybody on the
internet can reach, and what decides whether a request is obeyed is the credential it carries.
That is why **identity is called the new perimeter**: the question "who can reach the controls" has
become "who holds a valid key", and lessons 6 and 7 are about keeping that set small.

**2. Configuration is the system.** The firewall, the disk encryption and the list of who may read a
file are all settings in the same API, changed by the same kind of call. On premises, publishing a
file share to the internet takes a server team, a network team, a firewall rule and a change ticket.
In the cloud it is one request, it takes effect in seconds, and nobody else has to agree. Lesson 9
is that request and what it has cost.

**3. Inventory is a query.** You cannot walk the racks, but you can ask: every bucket, every user,
every network, in every region. That cuts both ways. The answer is complete and instant, which no
spreadsheet of servers ever was. And a resource in a region nobody looks at is still running,
still reachable, and still on the bill.

**4. Things are short-lived.** A machine may live for twenty minutes, and the address it had is
handed to somebody else's machine afterwards. An investigation cannot pull a disk out of a server
that no longer exists, so what you will want to know afterwards has to be recorded while it
happens. Lesson 15 is about what records it.

**5. You cannot touch the wire.** There is no switch to mirror, no cable to tap, no console port.
What you can see of your own network and your own API calls is what the provider offers to record,
and most of it is **off until you turn it on, and billed when you do**.

**6. The bill is a sensor.** A stolen key is often put to work mining cryptocurrency on the
largest machines the account allows, and the first symptom is a bill that is ten times last month's.
The `cloud` course's lesson 10 set budget alerts for money; the same alert is a security alarm.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-steps\" aria-label=\"What it takes to make stored files reachable from the internet. On premises, four steps by four different people: the server team shares the directory, the network team puts the server where the internet can reach it, the firewall team opens a rule, and a change board approves. Any one of them can say no. In the cloud, one request to the API, put-bucket-policy, sent by whoever holds a key allowed to send it, takes effect in seconds, and nobody else has to agree.\"><defs><marker id=\"l01-steps-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">on premises</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">in the cloud</text><path d=\"M360.0 14.0 L360.0 316.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"40.0\" y=\"50.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">share the directory</text><text x=\"56.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">server team</text><text x=\"304.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">1</text><path d=\"M180.0 102.0 L180.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"114.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">move it where the internet reaches</text><text x=\"56.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">network team</text><text x=\"304.0\" y=\"139.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">2</text><path d=\"M180.0 166.0 L180.0 176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"178.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">open a firewall rule</text><text x=\"56.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">firewall team</text><text x=\"304.0\" y=\"203.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">3</text><path d=\"M180.0 230.0 L180.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"242.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">approve the change</text><text x=\"56.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">change board</text><text x=\"304.0\" y=\"267.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">4</text><text x=\"180.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">any one of four people can say no</text><rect x=\"400.0\" y=\"130.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws s3api put-bucket-policy</text><text x=\"540.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">whoever holds a key that may send it</text><text x=\"540.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">in effect in seconds</text><text x=\"540.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nobody else has to agree</text></svg>", "caption": "The same outcome, four approvals against one request. The cloud did not remove the decision; it removed the people who used to stand in front of it."}
```

## What does not change

The ideas do not. Confidentiality, integrity and availability; least privilege; defence in depth;
knowing what you have before defending it: the `security-fundamentals` course taught them for any
computer, and none of them is retired here. What changes is **where each idea is enforced**. Least
privilege used to be a matter of who had a login to which server, and it is now a policy document
attached to an identity. Segmentation used to be VLANs and a firewall in a rack, and it is now a
route table and a security group that are, again, settings.

Which is the thread of this course: **in the cloud, almost every defence is a setting, and so is
almost every failure.** The next section shows both in your lab.
