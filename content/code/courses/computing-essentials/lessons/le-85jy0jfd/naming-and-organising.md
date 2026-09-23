---
title: Naming, which is the only part of this that is work
version: 2
---

Everything before this section was how the filesystem behaves. This one is the habit that decides
whether any of it helps you, and it is smaller than people expect: **a file's name should say
what it is without anybody opening it.**

## The date rule, which pays for itself in a week

Put the date at the front, and write it **year, month, day**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two lists of the same five invoice files, each sorted the way a computer sorts names. On the left the dates are written year first and the list comes out in date order, from November 2025 to November 2026. On the right the same dates are written day first and the list comes out ordered by day of the month, with the oldest file at the bottom.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same five files, sorted by the same rule</text><rect x=\"24\" y=\"36\" width=\"326\" height=\"188\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"370\" y=\"36\" width=\"326\" height=\"188\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the year written first</text><text x=\"390\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the date written the usual way</text><text x=\"44\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2025-11-30-invoice.pdf</text><text x=\"390\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">02-03-2026-invoice.pdf</text><text x=\"44\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-01-08-invoice.pdf</text><text x=\"390\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">05-11-2026-invoice.pdf</text><text x=\"44\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-02-14-invoice.pdf</text><text x=\"390\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">08-01-2026-invoice.pdf</text><text x=\"44\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-03-02-invoice.pdf</text><text x=\"390\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14-02-2026-invoice.pdf</text><text x=\"44\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-11-05-invoice.pdf</text><text x=\"390\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">30-11-2025-invoice.pdf</text><text x=\"44\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">in date order, for free</text><text x=\"390\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">in no order at all</text><text x=\"24\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A computer sorts names character by character. Writing the year first is what makes the two agree.</text></svg>", "caption": "Nothing was sorted by hand on either side. The left-hand list is what the file manager does with no help at all."}
```

A computer sorts names character by character. `2026-01-08` and `08-01-2026` describe the same
day, and only one of them puts the files in date order when sorted by name — which is the order
every file manager offers by default and the order you want almost every time.

It is a real standard, `ISO 8601`, and it is unambiguous besides: `03-04-2026` is March in one
country and April in another, and `2026-04-03` is April everywhere.

## What a good name contains

`2026-03-14-tavares-contract-signed.pdf`

- **the date**, front, ISO;
- **who or what it belongs to**;
- **what it is**;
- **its state**, where that matters — `draft`, `signed`, `final`.

And what it does not contain: `final`, `final2`, `FINAL-real`, `v2-new`. If you need versions,
number them with leading zeros — `v01`, `v02` — so that ten sorts after nine.

## Folders: shallow, and named for how you look

Two rules, and the second is the one that gets broken:

- **Three or four levels, not eight.** Every extra level is a decision to make when you file and
  a guess to make when you look.
- **Name folders the way you will search, not the way the thing is classified.** A folder called
  `clients/tavares` is findable. A folder called `business/active/2026/q1/correspondence` requires
  you to reconstruct somebody's taxonomy from memory.

When a file genuinely belongs in two places, that is what a shortcut is for — and it is one of
the few honest uses of one.

## The four folders that cover most of a life

```localised
documents/
  2026/           ← things that belong to a year
  reference/      ← things that do not change
  projects/       ← things being worked on now
  archive/        ← things that are finished
```

The interesting one is `archive/`. **Moving a finished project out of `projects/` is the step
that keeps the current list short**, and a short current list is the whole benefit. Nothing is
deleted; it stops being in the way.

## Two things not to do

**Do not organise by file type.** A folder of `pdfs` and a folder of `spreadsheets` is a
classification nobody searches by — you look for *the Tavares contract*, not *a PDF*.

**Do not rely on tags alone.** Tags are genuinely good and they are not portable: they live in
one system's database, they rarely survive a copy to another machine or a cloud service, and
they are invisible to every other program. Use them on top of a folder structure, never instead
of one.

## And the one sentence to keep

**Name a file for the person who will look for it in two years, and that person is you.** Every
rule above is a consequence of that, including the ones that feel fussy on the day.
