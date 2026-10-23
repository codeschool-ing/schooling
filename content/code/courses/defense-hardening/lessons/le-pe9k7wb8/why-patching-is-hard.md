---
title: Why patching is hard
version: 1
---

**Installing an update takes a minute. Patching is everything around that minute.** The common
picture is that patching is a technical task somebody keeps putting off. In practice the minute is
the easy part; what takes the time is deciding when the update can go in, finding out whether it
breaks anything, putting it on machines in an order that limits the damage if it does, and handling
the machines it cannot go on yet.

Two duties pull against each other. Lesson 16 gives every finding a due date, because an unpatched
flaw is a risk that grows with every day. The firm's clients expect the portal to answer, because a
patch that takes it down is an outage the firm caused itself. **A patching process is the
arrangement that lets both be true**: updates go in quickly, and when one is bad, few machines get
it and it comes out again fast.

## The window

A **maintenance window** is a time agreed in advance when changes may cause interruptions: Tuesday
night for the portal, say, when Jatobá's clients are not filing anything. A window makes patching
predictable for the people who depend on the service, and it gives the people who patch a slot
nobody argues about. It also creates the tension the next sections resolve: a flaw on the
exploited list cannot wait six days for Tuesday, so the process needs a rule for when the window is
bypassed, and that rule is lesson 16's P1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l17-timeline\" aria-label=\"A timeline of one update over thirty days. Day 0, the fix is published and enters the firm's repository. Day 1, ring one, the first few machines, gets it. Day 8, after a week without trouble, ring two, everything else, gets it in the Tuesday maintenance window. Day 30 is the due date from the vulnerability policy, with time to spare. A dashed line marks the faster path for a flaw being exploited: both rings within the seven days of a P1.\"><defs><marker id=\"l17-timeline-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M60.0 120.0 L680.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M60.0 116.0 L60.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 0</text><path d=\"M204.7 116.0 L204.7 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"204.7\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 7</text><path d=\"M349.3 116.0 L349.3 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"349.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 14</text><path d=\"M494.0 116.0 L494.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"494.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 21</text><path d=\"M680.0 116.0 L680.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 30</text><circle cx=\"60.0\" cy=\"120.0\" r=\"5\" fill=\"var(--paper)\"></circle><path d=\"M60.0 114.0 L60.0 50.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"66.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fix published,</text><text x=\"66.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the repository</text><circle cx=\"80.7\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M80.7 114.0 L80.7 98.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"86.7\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ring one</text><text x=\"86.7\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a few machines</text><circle cx=\"225.3\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M225.3 114.0 L225.3 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"231.3\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ring two, Tuesday</text><text x=\"231.3\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">window, everything else</text><circle cx=\"680.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M680.0 114.0 L680.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"674.0\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">due date</text><text x=\"674.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">P2 policy</text><path d=\"M60.0 175 L204.7 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l17-timeline-dh-ah-amber)\"></path><text x=\"212.7\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">exploited flaw (P1): both rings inside seven days</text></svg>", "caption": "The rings fit inside the deadline. For an exploited flaw they shrink to hours, not to nothing."}
```

## What this lesson builds

Most of what a firm patches comes from its distribution, and this lab cannot reach Ubuntu's
archive. So the lesson patches software the firm makes itself: a small package, `jatoba-health`,
which checks that the portal answers. It is built on `admin` in two versions, served from a
repository of the firm's own, and rolled out to `desk` and `web` in two rings, put on hold on one
machine, and rolled back on another. **The mechanics are the same for nginx from Ubuntu as for a
package of your own**, which is why this is a fair stand-in: apt does not know who wrote what it
installs.

Start the lab for this lesson:

```sh
sudo bash hostlab.sh up admin desk web
```
