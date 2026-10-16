---
title: Your lab, and three ways to have it
version: 1
---

This course is learnt by typing. Every lesson shows a query and what came back, and the point of
showing what came back is that you run the same query and compare. **The platform does not run a
database for you**, and nothing in this course needs anything you did not install yourself.

What you need, by the end of lesson 5, is one machine with four programs on it: PostgreSQL,
Metabase, a Python environment for Streamlit, and a way to reach them from your terminal and your
browser. This lesson sets up the first; lessons 3 and 5 add the other two to the same machine.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"lab-ports\" aria-label=\"Two boxes. On the left, your computer, with a terminal and a web browser. On the right, the virtual machine Ubuntu runs in, holding PostgreSQL on port 5432, the SSH server on port 22, Metabase on port 3000 and Streamlit on port 8501. Three arrows cross from left to right: the terminal reaches SSH through forwarded port 2222, and the browser reaches Metabase through 3000 and Streamlit through 8501. PostgreSQL has no arrow from outside: only programs inside the machine talk to it.\"><defs><marker id=\"lab-ports-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"230\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">your computer</text><rect x=\"45\" y=\"80\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">terminal</text><text x=\"135\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ssh -p 2222 ana@localhost</text><rect x=\"45\" y=\"160\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">web browser</text><text x=\"135\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:3000</text><text x=\"135\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:8501</text><rect x=\"410\" y=\"30\" width=\"290\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"555\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">the virtual machine (Ubuntu)</text><rect x=\"440\" y=\"62\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">SSH server</text><text x=\"655\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:22</text><rect x=\"440\" y=\"112\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Metabase</text><text x=\"655\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3000</text><rect x=\"440\" y=\"162\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Streamlit</text><text x=\"655\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8501</text><rect x=\"440\" y=\"212\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">PostgreSQL</text><text x=\"655\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:5432</text><line x1=\"225\" y1=\"107\" x2=\"438\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"330\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2222 → 22</text><line x1=\"225\" y1=\"200\" x2=\"438\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"318\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"225\" y1=\"218\" x2=\"438\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8501</text><path d=\"M672 130 L688 130 L688 230 L674 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" marker-end=\"url(#lab-ports-ah)\"></path><text x=\"320\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-style=\"italic\">nothing outside reaches 5432</text></svg>", "caption": "Everything runs inside the virtual machine; the terminal and the browser stay on your computer and reach in through three forwarded ports."}
```

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
that you can break and throw away without touching anything else. Run **Ubuntu Server 24.04 LTS**
in one and you have the exact system this course was recorded on.

**If you took `sql-databases`, you already have this machine.** Its lesson 1 built it, with
PostgreSQL 16 and a role in your name. Start it, and skip to the next section's
`createdb lantern`.

Otherwise, the program that runs the machine is a **hypervisor**:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

1. Install the hypervisor, and download the Ubuntu Server 24.04 LTS installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a machine from that image with **2 processors, 4 GB of memory and a 25 GB disk**.
   PostgreSQL alone would live in 2 GB, but Metabase, from lesson 3, is a Java program that
   holds a large share of memory by itself, and lesson 3 measures how much.
3. Start it and accept the installer's defaults, with one exception: on the screen that offers
   **Install OpenSSH server**, tick it. It asks for your name, a name for the server and a
   username — pick ones you will remember.
4. When it reboots, log in. You are at a prompt like `ana@vm:~$`.

## Reaching into the machine

The virtual machine's own window is a poor place to work: on most hypervisors you cannot paste
into it, and lesson 1 asks you to paste a 165-line script. So you will work from a terminal on
your own computer, connected to the machine over SSH, and open Metabase and Streamlit in your own
browser. The machine has to let those three connections in.

**On VirtualBox**, the machine sits behind its own private network, and you open a door per
program. With the machine switched off, open its **Settings → Network → Adapter 1 → Advanced →
Port Forwarding**, and add three rules:

| name | host port | guest port |
|---|---|---|
| ssh | 2222 | 22 |
| metabase | 3000 | 3000 |
| streamlit | 8501 | 8501 |

Then, from a terminal on your computer — Terminal on a Mac, PowerShell or Windows Terminal on
Windows — connect with `ssh -p 2222 ana@localhost`, using your username. The browser addresses
are `http://localhost:3000` and `http://localhost:8501`.

**On UTM**, the default network gives the machine an address your Mac can reach directly. Ask the
machine for it with `hostname -I`, and use that address instead of `localhost`: `ssh
ana@192.168.64.5`, `http://192.168.64.5:3000`. No forwarding is needed.

**What it costs your computer:** 4 GB of memory while the machine runs, and the disk it grows
into — a few gigabytes for Ubuntu, plus what Metabase and Streamlit add, which lessons 3 and 5
measure when they install them.

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine;
> in yours they are the names you chose. Every command is the same.

## Installed directly on your computer

If your computer **already runs Ubuntu or Debian**, skip the virtual machine and the forwarding:
every command in this course works on it as printed, and the addresses are `localhost`. It is the
cheapest path there is.

On **macOS** and **Windows**, all three programs install natively — PostgreSQL from
postgresql.org or Postgres.app, Metabase as a Java file or a Docker container, Streamlit with
Python's `pip`. It costs a few hundred megabytes and a database server running in the background.
What it does not give you is the same steps: each installer creates the first database user its
own way, so the setup in the next section will not match what you see. Everything after it,
which is SQL, will.

## Online, on somebody else's server

Hosted PostgreSQL services give you a database and an address to connect to, and several have a
free tier. **It costs your computer nothing**, and it needs an account and a connection. It also
covers only the first of the four programs: Metabase and Streamlit would still need a machine of
your own, or a hosted plan of their own.

Use it to start if the other two are out of reach today, and plan to move. A free tier is a
company's offer, offers change their terms, and no lesson in this course depends on any provider.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu. It costs an afternoon once, and it
buys the one property the others do not have: **when your screen and the transcript disagree, the
difference is in what you typed**, not in which system you are on.
