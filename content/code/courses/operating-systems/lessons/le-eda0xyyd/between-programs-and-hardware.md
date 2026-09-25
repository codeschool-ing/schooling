---
title: Between your programs and the hardware
version: 1
---

**An operating system is the program that runs the computer for the other programs.** A browser, a
spreadsheet and a terminal each want the processor, some memory, the disk, the screen and the
network, all at once. If each one talked to the hardware on its own, they would overwrite each
other's memory, write to the disk at the same time and fight over the screen. The operating system
sits in the middle and makes them take turns.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three layers. At the top, programs: a browser, a spreadsheet, a terminal. In the middle, the operating system, whose kernel manages processes, memory, devices and files. At the bottom, the hardware: processor, RAM, disk, and the screen, keyboard and network. Programs reach the hardware only by asking the kernel, through system calls such as open, read, write, start and stop.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">programs</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">browser</text><rect x=\"250\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">spreadsheet</text><rect x=\"480\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">terminal</text><path d=\"M125 80 L125 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M355 80 L355 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M585 80 L585 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"690\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">system calls: open, read, write, start, stop</text><rect x=\"20\" y=\"122\" width=\"680\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">operating system</text><text x=\"34\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">kernel</text><rect x=\"100\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"168\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processes</text><rect x=\"250\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">memory</text><rect x=\"400\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">devices</text><rect x=\"550\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"618\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">files</text><path d=\"M168 212 L168 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M318 212 L318 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M468 212 L468 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M618 212 L618 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"20\" y=\"250\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">hardware</text><rect x=\"100\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"168\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">processor</text><rect x=\"250\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"318\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">RAM</text><rect x=\"400\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"468\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">disk</text><rect x=\"550\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"618\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">screen, keyboard, network</text></svg>", "caption": "No program touches the hardware directly. It asks the kernel, and the kernel decides."}
```

The part that does the refereeing is the **kernel**. It is the first program loaded when the
computer starts and the last one to stop, and it is the only program allowed to touch the hardware
directly. Everything else, including the parts of the system you see, asks the kernel for what it
needs through **system calls**: open this file, read from it, start that program, give me more
memory. Section 06 watches a program do exactly that.

## What it looks after

- **Processes**: every running program, which ones exist, which one runs next.
- **Memory**: who gets which part of the RAM, and what happens when there is not enough.
- **Devices**: disks, keyboards, screens, printers and network cards, each through a **driver**.
- **Files**: turning a disk full of numbered blocks into folders and names.

It also keeps track of **users** and what each one is allowed to do, which is lessons 9 and 10.

## Three systems, one idea

| | Windows | Linux | macOS |
|---|---|---|---|
| kernel | Windows NT | Linux | XNU |
| comes from | Microsoft, 1993 | Linus Torvalds, 1991 | Apple, built on Unix (BSD) code |
| where you meet it | most office desktops | most servers, Android phones | Apple computers |
| who ships it | Microsoft | many *distributions* (lesson 6) | Apple |

Linux on its own is only the kernel. What people install is a **distribution**, the kernel plus
the programs around it, and there are many. Windows and macOS each come from one company, whole.

At the office, all three are in use at once, and that is normal. Ana's job is not to prefer one of
them. It is to recognise the same idea behind three different screens, and that starts with the
processes.
