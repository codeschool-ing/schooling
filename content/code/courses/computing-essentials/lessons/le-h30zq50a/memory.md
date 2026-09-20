---
title: Memory, and the word that explains every "it lost my work"
version: 1
---

RAM — random-access memory — holds what the computer is working on **right now**. Every running
program, every open document, the operating system itself. The processor can read any of it in
about a hundred nanoseconds, which is why work happens there and not anywhere else.

One property decides everything else about it: **RAM is volatile.** Cut the power and it is
blank. Not corrupted, not partially there — blank, as though it had never held anything.

That is not a flaw anybody is working to fix. It is the trade that makes RAM fast enough to be
worth having, and the reason `Ctrl+S` exists at all.

> **The most expensive sentence in this section.** A document you have typed and not saved exists
> in exactly one place, and that place is erased by a power cut, a flat battery or a crash. The
> program did not "lose" it. It was never anywhere that could keep it.

## How much is enough, and what "not enough" looks like

The honest answer in the mid-2020s, for a general machine:

| | |
|---|---|
| 8 GB | a browser and one other thing. Workable, and you will meet the ceiling |
| **16 GB** | **the sensible default.** Browser with many tabs, an office suite, a video call |
| 32 GB and up | video editing, virtual machines, large datasets |

What matters more than the number is recognising the ceiling when you hit it, because the
symptom is specific and nothing else produces it.

## Swapping: what a full desk actually does

When RAM fills, the operating system does not refuse to open the next program. It picks
something that has not been touched in a while, **writes it out to storage**, and hands the freed
memory over. When you click back to that window, it has to be read in again — and something else
gets written out to make room for it.

That is **swapping**, and it is the reason the desk metaphor earns its place. The worker is not
working. The worker is carrying paper to and from the cabinet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"Two rows. The top row, marked enough memory, shows four programs sitting inside a memory bar with room to spare, and a note that switching between them is instant. The bottom row, marked memory full, shows four programs that do not fit: one is pushed out to a wide storage box below, by an arrow marked written out, and an arrow back up marked read in again when you click that window. A note reads that the machine is busy and getting nothing done, and that this is what a computer that feels stuck is usually doing.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The same four programs, on a machine with room and on a machine without it.</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">enough memory</text><rect x=\"14\" y=\"56\" width=\"520\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"256\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"372\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"73\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">switching is instant</text><text x=\"14\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">memory full</text><rect x=\"14\" y=\"128\" width=\"520\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the fourth does not fit</text><rect x=\"14\" y=\"178\" width=\"520\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"24\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storage</text><rect x=\"192\" y=\"194\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M270 160 L270 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M270 192 L266 184 L274 184 Z\" fill=\"var(--amber)\"></path><text x=\"282\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">written out</text><path d=\"M360 203 L520 203\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M522 203 L514 199 L514 207 Z\" fill=\"var(--amber)\"></path><text x=\"546\" y=\"203\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and read back when you click it</text><text x=\"14\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Busy, and getting nothing done. A computer that feels stuck is usually doing this.</text></svg>", "caption": "Nothing is broken in the bottom row. The machine is working as designed, and the design is to slow down rather than refuse."}
```

The symptoms are unmistakable once you know them:

- the whole machine becomes slow, not one program;
- the storage light — or the disk graph in the task manager — is busy while the processor is
  mostly idle;
- **switching between windows** is what hurts, and switching back and forth hurts most.

That last one is the giveaway. A slow processor makes one task slow. Swapping makes *changing
your mind* slow.

## Which is why the advice is what it is

"Close some tabs" is not folk wisdom. Every tab is paper on the desk, and the cheapest way to
stop the carrying is to need less room. And when a machine is at its ceiling, **more memory is a
far better purchase than a faster processor** — you are not buying speed, you are buying the
absence of that carrying.
