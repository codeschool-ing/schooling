---
title: Memory, and what happens when it runs out
version: 1
---

**RAM is where running programs keep what they are working on.** It is fast, it is much smaller
than the disk, and it is emptied every time the computer turns off. The kernel decides who gets
which part of it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two processes, the browser and the spreadsheet, each see their own range of addresses starting from zero. The kernel maps pieces of each range onto places in physical RAM, interleaved, and some pieces of the spreadsheet onto the disk, in swap or the pagefile. Neither process can see the other&#x27;s pieces.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the browser sees</text><rect x=\"20\" y=\"34\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><rect x=\"20\" y=\"114\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8192</text><rect x=\"20\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12288</text><text x=\"560\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the spreadsheet sees</text><rect x=\"560\" y=\"34\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"560\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><rect x=\"560\" y=\"114\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8192</text><rect x=\"560\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12288</text><text x=\"20\" y=\"214\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own addresses, from 0 up</text><text x=\"290\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">physical RAM</text><rect x=\"290\" y=\"34\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"58\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"82\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"106\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"130\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"154\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"178\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"236\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">disk (swap / pagefile)</text><path d=\"M162 49 C220 49 240 44 286 44\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 89 C220 89 240 92 286 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 129 C220 129 240 140 286 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 169 C220 169 240 188 286 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 49 C500 49 480 68 434 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 89 C500 89 480 116 434 116\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 129 C500 129 480 164 434 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 169 C500 169 480 248 434 248\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Each process believes it has a private memory starting at zero. The kernel keeps the real map, and can move quiet pieces out to disk."}
```

Every process sees its own addresses, starting from zero, and cannot see anybody else's. This is
**virtual memory**: the kernel keeps a map from each process's addresses to real places in RAM.
It is why one program crashing does not take the others down with it, and why a program cannot
simply read the password another program is holding.

## Reading the numbers

```
ana@server:~/office$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       638Mi        13Gi        12Mi       2.2Gi        15Gi
Swap:             0B          0B          0B
```

Read it from right to left, because the column that matters is the last one:

- *total*: the RAM in the machine, 15 GiB here.
- *used*: taken by processes.
- *buff/cache*: files the kernel has kept in RAM because they were read recently. It is not
  wasted; reading them again is instant. And it is given back the moment a program needs it.
- *available*: what a new program could get right now, cache included. **This is the number to
  look at.** A machine with little *free* and plenty *available* is healthy.

## When it runs out

When programs want more RAM than exists, the kernel moves pieces nobody is using right now onto the
disk, and brings them back when they are needed. That area of the disk is *swap* on Linux, the
*pagefile* (`pagefile.sys`) on Windows and *swap files* on macOS. Windows and macOS also
compress memory before resorting to the disk.

It keeps the machine running, and it is slow: a disk is thousands of times slower than RAM. A
computer that has run out of memory feels sluggish in a particular way. The mouse moves, but every
window takes seconds to respond, and the disk light stays on. That is the *waiting for something
else* of the last section, and the usual cure is fewer programs open, or more RAM.

This server shows `Swap: 0B`: it has none configured, so it cannot do this at all. Where that is
the case, the kernel's last resort is to stop a process to free memory, on Linux by a mechanism
called the **OOM killer** (*out of memory*).

The Windows equivalent of `free` is the *Performance* tab in Task Manager, and on macOS it is the
*Memory* tab of Activity Monitor. Both show the same idea: in use, cached, and compressed.
