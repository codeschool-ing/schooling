---
title: A machine's worth of control
version: 1
---

The next step is to be given a machine — not a folder on one — and with it every decision and every
consequence that the previous section's provider was absorbing on your behalf.

## Virtual, and what that means

Almost nobody is handed physical hardware. A **virtual private server** is a slice of a real
machine, isolated from the other slices by the same technology that runs most of the internet.

The word private is the important one. You get a fixed allocation of processor, memory and disk
that is *yours* — a neighbour's load does not take it — and an operating system of your own with
administrative access. You choose the distribution, install what you like, configure the web server
yourself, and run anything you can run on a computer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A physical machine divided into slices. Each slice has a fixed allocation of processor, memory and disk and its own operating system, so a neighbour's load does not take yours.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">one physical machine, divided</text> <rect x=\"40\" y=\"70\" width=\"200\" height=\"94\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"140\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">yours</text> <text x=\"140\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2 processors, 4 GB</text> <text x=\"140\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an operating system</text> <text x=\"140\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">of your own</text> <rect x=\"252\" y=\"70\" width=\"200\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"352\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">somebody else's</text> <text x=\"352\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2 processors, 4 GB</text> <text x=\"352\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">whatever they run</text> <rect x=\"464\" y=\"70\" width=\"216\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"572\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">and more slices</text> <text x=\"572\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each with a fixed share</text> <text x=\"572\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">that is theirs alone</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the allocation is the difference: a busy neighbour cannot take yours</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and so is everything on that machine now being your responsibility</text> </svg>", "caption": "A fixed share and an operating system of your own. Both halves of that are the trade."}
```

A **dedicated server** is the same arrangement without the slicing: the whole physical machine.
Worth more when you need every bit of the hardware, when a licence is priced per machine, or when a
rule says your data may not share hardware with anybody. For most work the virtual one is
indistinguishable and much cheaper.

## What you have just taken on

Say this explicitly, because it is the whole trade and it is usually discovered rather than
decided.

**Security updates.** Nobody applies them for you. An unpatched machine on a public address is
found by automated scanning within hours of going up, and that is not an exaggeration — it is what
the logs of any new server look like.

**The web server.** Installing, configuring, and the reverse proxy in front of your application.

**Certificates.** Obtaining them and renewing them, which is the last reading of this lesson
because it is where the most sites break.

**Backups.** The provider snapshots the disk if you ask and pay; nobody backs up your database
unless you arrange it, and a backup nobody has restored is a hope rather than a backup.

**Being woken up.** There is no support queue that fixes your application. The provider's
responsibility ends at the hardware and the network.

That list is not an argument against it. It is the price, and it is worth paying when you need what
it buys — which is the ability to run whatever you want, however you want, at a cost that stops
scaling with your ambitions.

## What it costs, and the shape of the curve

A small virtual server is a few currency units a month and will carry a surprising amount of
traffic. A larger one is a multiple of that.

The relevant thing is the shape rather than the number: **it is fixed.** A quiet month costs what a
busy month costs. That is an advantage over the pricing in the next reading when your load is
steady and a disadvantage when it is not, and it is the single most useful thing to know when
comparing the two.

## Sizing, which people get wrong in both directions

The instinct is to buy generously. The better instinct is to buy small and watch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three resources compared: memory runs out abruptly and kills a process, disk fills quietly and locks you out, and the processor is usually the last constraint to bind.\"> <rect x=\"20\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"128\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">memory</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">runs out abruptly</text> <text x=\"128\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the system kills your</text> <text x=\"128\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">largest process</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">disk</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">fills quietly</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and then nothing can</text> <text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">write, including you</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">processor</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">usually the last one</text> <text x=\"592\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">to bind, and the one</text> <text x=\"592\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the pricing page sells</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">buy small and watch, and leave the headroom on memory</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">rotating the logs is a five-minute job that prevents an outage with no obvious cause</text> </svg>", "caption": "Three resources, three different ways of failing, and the pricing pages are organised around the least dangerous."}
```

Most small applications are limited by **memory** long before processor, and the failure when
memory runs out is abrupt: the system kills the largest process, which is your application or your
database, and the site goes down rather than slowing down. That asymmetry is the argument for
leaving headroom on memory specifically.

Disk is the one that fails quietly and is forgotten. Logs grow. A machine with a full disk cannot
write a log entry, cannot write a session, and often cannot be logged into to fix it. Rotation of
logs is a five-minute job that prevents an outage with no obvious cause.

And processor is usually the last constraint to bind, which is the opposite of what the pricing
pages encourage you to believe.

## The first hour on a new machine

Not a checklist to memorise, and worth seeing once, because a machine left as it arrives is a
machine that is found.

**Updates first.** Before anything else runs, apply what is waiting, and arrange for security
updates to keep arriving.

**Stop password logins.** Use a key, and turn off the password route entirely. The scanning that
finds your machine is guessing passwords, and a key makes that attempt pointless rather than slow.

**Close everything you are not using.** A firewall that permits the web ports and your way in, and
refuses the rest. Databases in particular should be listening to the machine rather than to the
world, and the number of databases on the public internet with a default password is a well
documented and depressing figure.

**Do not run the application as the administrator.** A separate account with no more access than
the application needs turns a compromise into a smaller compromise.

**Decide the backups now**, while the machine is empty and it takes ten minutes, rather than after
there is something on it worth losing.

## The thing that makes it worth it

One practical note to end on, because it is easy to miss while reading a list of chores.

A machine you control is a machine you can **reproduce**. The configuration can be in a file, the
file can be in a repository, and a new machine can be built from it in minutes. That is not
available to you on shared hosting at any price, and it is what turns a server from something you
are afraid to touch into something you can throw away and rebuild.

If you take on a machine, take that on with it. A server nobody can rebuild is a server that
eventually cannot be upgraded, and the reason for that is always the same: nobody remembers what is
on it.
