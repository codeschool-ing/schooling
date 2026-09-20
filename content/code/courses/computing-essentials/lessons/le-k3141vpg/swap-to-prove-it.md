---
title: Swap it, which is the only move that proves anything
version: 1
---

Everything so far narrows the search. **Substitution is the move that ends it**: put a
known-good thing in place of the suspect, or put the suspect somewhere known-good, and watch
which way the symptom goes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A table of four swaps. Moving the monitor to another machine: if the symptom moves the monitor is faulty, if it stays the machine or the cable is. Moving the cable onto something that works: if the symptom moves the cable is faulty, if it stays the cable is fine. Running the program in a second account: if the symptom moves it is the program or the machine, if it stays it is the first account settings. Starting the whole system from a live stick: if the symptom moves the hardware is faulty, if it stays the installation is.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The symptom follows the faulty part</text><text x=\"44\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the swap you make</text><text x=\"292\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the symptom moved with it</text><text x=\"500\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the symptom stayed behind</text><rect x=\"24\" y=\"64\" width=\"248\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the monitor, into another machine</text><rect x=\"280\" y=\"64\" width=\"208\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the monitor is faulty</text><rect x=\"496\" y=\"64\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"508\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the machine or the cable is</text><rect x=\"24\" y=\"122\" width=\"248\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the cable, onto something that works</text><rect x=\"280\" y=\"122\" width=\"208\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the cable is faulty</text><rect x=\"496\" y=\"122\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"508\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the cable is fine</text><rect x=\"24\" y=\"180\" width=\"248\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the program, into a second account</text><rect x=\"280\" y=\"180\" width=\"208\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the program or the machine</text><rect x=\"496\" y=\"180\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"508\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the first account settings</text><rect x=\"24\" y=\"238\" width=\"248\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"263\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the whole system, from a live stick</text><rect x=\"280\" y=\"238\" width=\"208\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"263\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the hardware is faulty</text><rect x=\"496\" y=\"238\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"508\" y=\"263\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the installation is</text><text x=\"24\" y=\"312\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Either outcome settles a half. There is no result here that leaves you where you started.</text></svg>", "caption": "A swap says WHERE the fault is and never what it is — and for almost everything anybody does at home, where is enough."}
```

## The symptom follows the faulty part

That is the whole idea, and it is worth saying as a sentence you can apply anywhere:

- **The monitor is black.** Plug that monitor into another machine. Works there, and the monitor
  is fine. Still black, and it is the monitor.
- **The cable is suspect.** Use it for something known to work. A cable is the cheapest swap in
  computing and the highest-yield: it is the part that gets moved, bent and stood on.
- **One program crashes.** Run it in a second user account on the same machine. Crashes there
  too, and it is the program or the machine; works there, and it is something in the first
  account's own settings.
- **The machine is slow.** Start it from a live USB stick, which runs a whole system without
  touching the installed one. Fast from the stick, and the hardware is fine and the installation
  is not.

Two directions, and both are swaps: move the suspect to a good place, or bring a good thing to
the suspect's place.

## What a swap proves, and what it does not

**It proves where the fault is, not what it is.** A monitor that stays black on a second machine
is faulty; that does not say whether it is the panel, the supply or the board inside it, and for
most purposes it does not matter.

Two traps:

- **The swap must be known-good, not merely different.** Two cables from the same drawer prove
  nothing when both have been in the drawer for the same ten years.
- **Change one thing, here too.** Swapping the cable and the socket in one move is exactly the
  mistake from the previous section wearing a hat.

## Safe mode, and what it is a swap of

Starting a machine in **safe mode** loads the system with almost nothing added: basic drivers, no
startup programs, nothing installed sitting in the way. It is a swap where the thing being
substituted is *everything that was added since the machine was new.*

So the reading is clean. **The fault disappears in safe mode**, and it is something added — a
driver, a startup program, a setting. **It happens in safe mode too**, and it is the hardware or
the system itself, and no amount of uninstalling will help.

That single test is worth more than a day of guessing, and it costs one restart.

## And the swap you cannot make

Sometimes there is nothing to swap with: one printer, one machine, one monitor. That is a real
limit and it is worth saying out loud rather than substituting a guess for it.

What replaces it is the narrowing from the earlier sections and, eventually, borrowing —
a cable from a neighbour, a monitor from work. **The question *what would I need to borrow to
settle this?* is often the fastest way to see what you actually suspect.**
