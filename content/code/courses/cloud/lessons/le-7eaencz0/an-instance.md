---
title: An instance is a slice of somebody else's machine
version: 1
---

The picture most people bring to their first instance is a server in a rack with their name on it:
a whole computer, rented instead of bought. **That picture is wrong in the part that matters.** An
instance is a virtual machine, and it runs on a physical host that the provider owns, operates and
shares, in the ordinary case with other customers you will never hear about.

Between the hardware and every instance on it sits a **hypervisor**, the software (and on newer
hosts, dedicated hardware) whose one job is to divide the machine. It hands each guest some
processor threads and a fixed amount of memory, gives it virtual network cards and disks, and keeps
it from seeing or touching the guests beside it. Each instance boots its own operating system and
cannot tell, from the inside, how many neighbours it has.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One physical host run by the provider. Four slots sit on a hypervisor: your instance, two instances of other customers and free capacity. Below the hypervisor is the hardware. A dashed line marks where what you can see ends.\"><defs><marker id=\"host-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"12\" width=\"688\" height=\"278\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one physical host in the provider's data centre</text><rect x=\"36\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"111\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">your instance</text><text x=\"111\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"111\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own OS and programs</text><rect x=\"202\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">another customer</text><text x=\"277\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"277\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own OS and programs</text><rect x=\"368\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"443\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">another customer</text><text x=\"443\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"443\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own OS and programs</text><rect x=\"534\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"609\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">not yet rented</text><path d=\"M28 158 L692 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"36\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">what you see and manage</text><text x=\"36\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">what the provider runs and you never see</text><rect x=\"36\" y=\"184\" width=\"648\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hypervisor: divides the machine and keeps the guests apart</text><rect x=\"36\" y=\"230\" width=\"648\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CPUs, memory, network cards, local disks</text></svg>", "caption": "An instance is a slice of somebody else's machine. Everything above the dashed line is yours to see and configure; the hypervisor and the hardware below it are the provider's, and so are the neighbours beside you."}
```

The names differ and the thing does not. AWS calls it an EC2 instance, Google Cloud a VM instance,
Azure a virtual machine, DigitalOcean a Droplet and Hetzner a cloud server. This lesson uses AWS's
words because the price sheet the course quotes is AWS's; everything it says about the shape holds
for the others.

## What follows from the drawing

**You rent a slice, and you stop paying when you give it back.** Because the host is shared, the
provider can sell you two threads and eight gibibytes rather than a whole server, and bill for the
time you hold them. AWS bills a Linux on-demand instance by the second, with a one-minute minimum.
An instance switched off at six in the evening costs nothing for its processor overnight, which is
something a server in your own rack never did.

**The hardware is not yours to fix, and not yours to keep.** When a host develops a fault or is due
for maintenance, the provider tells you that the host under your instance is being retired, and
stopping and starting the instance puts it on a different host. Nobody walks to a rack for you, and
nobody asks whether the program you left running on that host kept anything important on it. That
is the reason the second half of this lesson spends so long on machines you can throw away.

**Where your responsibility starts is the dashed line.** Lesson 1 drew this for IaaS: the provider
runs the building, the hardware and the hypervisor, and you run the operating system and
everything on it. Patching the kernel of an instance is your job, exactly as it would be on a
machine under your desk. Keeping your neighbours out of your memory is the provider's.

**The neighbours are real.** They are walled off by the hypervisor, which is the security boundary
the whole arrangement rests on, and on most instance types the provider reserves the threads you
pay for so that a busy neighbour cannot take them. The exception is the burstable family in the
next section, which is cheap precisely because it shares more. When a rule or a contract demands
that no other customer ever runs on the same hardware, providers sell dedicated hosts, at a price
that shows how much of the discount came from sharing.

## What an instance is made of

Take the drawing apart and an instance is four things you choose, plus one the provider does:

| you choose | what it decides |
|---|---|
| an image | the disk it boots from: an operating system and whatever was installed on it |
| an instance type | how many processor threads and how much memory |
| a network placement | which network it sits in and which firewall rules guard it |
| its disks | what it keeps, and whether that outlives the instance |

The host it lands on is the provider's choice, and you are not told which one. The next four
sections take the rows in turn, and the last four ask what happens when there are many instances
instead of one.
