---
title: You cannot defend what you have not listed
version: 1
---

**Every lesson of this course has quietly assumed a list.** Lesson 1 removed the services `web` did
not need, which required knowing `web` existed and what its job was. Lesson 15 made servers accept
SSH only from the bastion, which works for the servers somebody configured. Lesson 16 compared
installed versions against advisories, on the machines somebody thought to check. Lesson 17 rolled
out updates in rings, to the machines in the rings. Each control is applied to "our machines", and
**it protects exactly the machines somebody remembered**.

That is why the first two of the CIS Critical Security Controls, the prioritised list published by
the Center for Internet Security, are not about firewalls or antivirus. Control 1 is an inventory of
enterprise assets: every device, with its owner and address. Control 2 is an inventory of software:
what is installed and allowed on each. They come first because every later control is applied to
their output, and a gap in them is a gap in all the others at once.

The common picture of an inventory is a spreadsheet somebody fills in once. The spreadsheet is half
of it. The other half is **measurement**: asking the network what is actually there and asking each
machine what it actually runs, and comparing that with what the spreadsheet says. Where the two
disagree is where the attacks of the earlier lessons get in: the server nobody patched because it was
not on the list, the service nobody hardened because nobody knew it was listening.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l18-loop\" aria-label=\"Two sources meet in a comparison. On the left, the records: hosts.csv with five machines, and a baseline per role. On the right, measurement: a sweep of the network that finds seven machines, and a collection from each machine of what it runs. In the middle, the comparison produces findings, each with an owner, and the fixes change the machines, which the next measurement sees.\"><defs><marker id=\"l18-loop-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-loop-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">what the firm says</text><text x=\"610.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">what is there</text><rect x=\"30.0\" y=\"40.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">hosts.csv</text><text x=\"110.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">five machines, owners</text><rect x=\"30.0\" y=\"120.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">baseline.json</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what each role runs</text><rect x=\"530.0\" y=\"40.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nmap -sn</text><text x=\"610.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seven machines answer</text><rect x=\"530.0\" y=\"120.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">inventory.py</text><text x=\"610.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what each one runs</text><rect x=\"280.0\" y=\"75.0\" width=\"160.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">drift.py</text><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">findings, with owners</text><path d=\"M190.0 65.0 L280.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M530.0 65.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M190.0 145.0 L280.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M530.0 145.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M360.0 135.0 L360.0 215.0 L610.0 215.0 L610.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-amber)\"></path><text x=\"485.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fixes change the machines; measure again</text></svg>", "caption": "An inventory is a list checked against measurement, not a list."}
```

## What this lesson builds

Three files and two scripts, all on `admin`: the firm's own list of machines, a **baseline** of what
each kind of machine should look like, a script that collects what every machine actually is, and a
script that reports where reality and the records disagree. Each script is short enough to read
whole, and each one is the core of what commercial asset-management and configuration tools do.

Start the whole lab: this is the one lesson that needs every machine.

```sh
sudo bash hostlab.sh up
```
