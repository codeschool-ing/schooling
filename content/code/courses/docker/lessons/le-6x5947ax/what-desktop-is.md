---
title: What Docker Desktop is
version: 1
---

**Docker Desktop is a Linux virtual machine with Docker inside, plus the tools to drive it from
your own operating system.** Lesson 2 settled why the VM has to be there: a Linux container needs a
Linux kernel, and Windows and macOS do not have one. Desktop's job is to start that kernel quietly,
keep it running, and make it feel as if `docker` were native.

The common misreading is that Desktop *is* Docker and that containers run "on Windows" or "on the
Mac". They run in the VM. The `docker` command you type stays on your own system and sends each
request into the VM, where the engine does the work. Everything this course teaches about the
engine is about the one inside.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A laptop running Windows or macOS. On it, the docker command and the Docker Desktop window. Inside the laptop, a Linux virtual machine managed by Desktop, holding a Linux kernel, Docker Engine and the containers. The docker command sends its requests across the boundary into the engine in the VM.\"><defs><marker id=\"l5desktop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5desktop-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">your laptop: Windows or macOS</text><rect x=\"30\" y=\"60\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">docker</text><text x=\"130\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the command you type</text><rect x=\"30\" y=\"140\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Docker Desktop window</text><text x=\"130\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">settings, lists, start/stop</text><rect x=\"290\" y=\"50\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"306\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Linux VM, managed by Desktop</text><rect x=\"310\" y=\"86\" width=\"360\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Docker Engine: dockerd, containerd, runc</text><rect x=\"310\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"366\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"434\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"558\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"614\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"310\" y=\"206\" width=\"360\" height=\"38\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Linux kernel</text><path d=\"M232 86 L306 106\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l5desktop-ah-amber)\"></path><path d=\"M232 166 L306 116\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5desktop-ah-wire)\"></path><text x=\"260\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requests</text></svg>", "caption": "The command runs on your system; the containers run in the VM. Every request crosses that boundary, and so does every file shared between the two."}
```

## What is in the box

- **A small Linux VM**, managed by Desktop: you never log into it, and Desktop updates it.
- **Docker Engine** inside the VM: `dockerd`, containerd and runc, the same pieces lesson 6 takes
  apart on a Linux server.
- **The command-line tools on your own system**: `docker`, with `docker compose` and `docker
  buildx` as plugins.
- **A graphical window** listing containers, images and volumes, with a settings screen. Anything
  it does can also be done from the command line, which is how this course does it.
- **Optional extras**: a single-node Kubernetes cluster you can switch on, extensions, and a
  sign-in to Docker's own services.

## Which VM, on which system

| your system | where the Linux kernel runs |
| --- | --- |
| Windows 10 or 11 | **WSL 2**, the Linux layer Microsoft ships with Windows (recommended), or a Hyper-V VM |
| macOS, Apple silicon or Intel | a VM started through Apple's virtualization framework |
| Linux | a VM too, using KVM: Desktop on Linux does not use the host's kernel directly |

The last row surprises people. **Docker Desktop for Linux still runs a VM**, so its containers are
separate from any Docker Engine installed on the same machine, with separate images and separate
containers. On a Linux machine most people install Docker Engine on its own instead, which is
lesson 6.

## The processor question on a Mac

**On an Apple silicon Mac the VM is `arm64`**, so images run natively when they are published for
`arm64`, which every official image is. An image published only for `amd64` still starts, through
emulation, either Apple's Rosetta or QEMU depending on a setting, and runs noticeably slower. Lesson
2 showed the error the same image gives on a Linux machine with no emulation set up; on the Mac it
runs, and the slowness is the symptom instead. When a team mixes Macs and Linux servers, lesson 13's
multi-platform build is how one tag serves both.

## The licence

Docker Desktop is free for personal use, education, non-commercial open-source projects and small
businesses. **Under Docker's terms as this lesson was written, a company with 250 or more employees
or more than 10 million US dollars in annual revenue needs a paid subscription to use it.** Those
terms have changed before, so check the current ones on Docker's site before a team standardises on
it. Docker Engine on Linux, lesson 6, is open source and has no such condition, and so are the
alternatives lesson 28 looks at, several of which also run a Linux VM on a Mac or a Windows machine
in the same way Desktop does.
