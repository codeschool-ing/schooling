---
title: From the file to the behaviour
version: 1
---

**An antivirus asks whether a file is bad. An EDR asks whether what the machine is doing is
bad.** Lesson 7 ended on the limit of the first question: a program nobody has seen before, a
script that never touches the disk, or an ordinary tool used for the wrong thing has no signature
to match. The second question does not need one. A shell started by the web server's account is
suspicious whatever that shell's file looks like, because the web server never needs a shell.

EDR stands for **endpoint detection and response**, and the name lists the parts in the order they
work:

| part | what it does | in this lesson |
|---|---|---|
| telemetry | a sensor on the machine records what happens: processes started, logins, files written, connections opened | `sensor.py`, under forty lines of Python |
| detection | rules run over the telemetry and raise an alert when one matches | `detect.py`, three rules |
| response | somebody, or the product on their behalf, acts on the machine: stops a process, keeps evidence, cuts the machine off the network | three commands and one `nftables` file |
| hunting | a person asks the stored telemetry a question no rule asked yet | one `jq` query, after the rules |

**The common picture of an EDR is a better antivirus, and it misses the most important part.** An
EDR keeps the telemetry, every process with its parents, for days or months, on a server away from
the machine. That record is what lets a responder answer the questions that matter after an alert:
what started this, what else did it start, and has anything like it happened on another machine.
An antivirus that blocks a file leaves no such trail.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-loop\" aria-label=\"The parts of an EDR as a loop. On the machine, a sensor records processes, logins, files and connections as telemetry. The telemetry is sent off the machine and kept. Rules run over it and raise an alert. A person reads the alert and acts on the machine: keeps the evidence, stops the process, isolates the host. A second arrow from the kept telemetry goes to hunting, a person asking a question no rule asked.\"><defs><marker id=\"l08-loop-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-loop-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"190.0\" height=\"150.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"40.0\" y=\"80.0\" width=\"150.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"115.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sensor</text><text x=\"115.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">processes, logins,</text><text x=\"115.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">files, connections</text><rect x=\"270.0\" y=\"80.0\" width=\"120.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"330.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">telemetry, kept</text><rect x=\"430.0\" y=\"80.0\" width=\"120.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"490.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rules</text><rect x=\"580.0\" y=\"80.0\" width=\"110.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"635.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alert</text><path d=\"M190.0 100.0 L270.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M390.0 100.0 L430.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M550.0 100.0 L580.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M635.0 120.0 L635.0 225.0 L115.0 225.0 L115.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-amber)\"></path><text x=\"375.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">response: keep evidence, stop, isolate</text><path d=\"M330.0 120.0 L330.0 165.0 L420.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><text x=\"428.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hunting: a question no rule asked</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">detection and response</text></svg>", "caption": "The sensor only writes things down. Everything that decides happens off the machine."}
```

## What this lesson builds, and what it does not

You will build a small EDR on `web` out of things that are already there: `/proc`, the journal,
Python and `nftables`. It works, and it fails in instructive ways, because a real product makes
different choices at exactly the points where this one is weak. The last section names them.

The incident you will detect is staged by you, in your own lab, with a harmless command: the
portal's account starts a shell, tries a download from an address where nothing answers, and
leaves a copy of `/bin/sleep` running from `/tmp`. Nothing is broken into. What matters to the
sensor is that it is the shape of what a real intrusion through a web application looks like from
the inside, and that the portal never does any of it on its own.

Start the lab with the three machines this lesson uses:

```sh
sudo bash hostlab.sh up web desk admin
```

`web` is the portal as `build` left it, with lesson 1's findings back in place, because every
lesson starts from a fresh copy. None of them changes what this lesson measures.
