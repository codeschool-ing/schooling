---
title: Versions, and why one copy of the latest thing is not enough
version: 1
---

A backup that keeps only the newest copy answers *the drive died*. It does not answer *the file
was already wrong when it was copied*, and the second is the more common failure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"A grid of two arrangements against four moments in time: before anything happens, the moment the files are encrypted, after the copy next runs, and when you notice. A mirror holds the good files for the first two moments, only the encrypted ones after the copy runs, and nothing to go back to when you notice. Thirty days of versions holds the good files throughout, and both the good and the encrypted ones once the copy has run.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Two arrangements, the same four moments</text><text x=\"245\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before</text><text x=\"369\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the moment it</text><text x=\"369\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypts</text><text x=\"493\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after the copy</text><text x=\"493\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">next runs</text><text x=\"617\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">when you</text><text x=\"617\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notice</text><text x=\"24\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a mirror</text><rect x=\"186\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the good files</text><rect x=\"310\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"369\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the good files</text><rect x=\"434\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"493\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">only the</text><text x=\"493\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">encrypted ones</text><rect x=\"558\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"617\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nothing to</text><text x=\"617\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">go back to</text><text x=\"24\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">thirty days of versions</text><rect x=\"186\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the good files</text><rect x=\"310\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"369\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the good files</text><rect x=\"434\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"493\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">both of them,</text><text x=\"493\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">and dated</text><rect x=\"558\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yesterday's</text><text x=\"617\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">good files</text><text x=\"24\" y=\"256\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The difference is not how often the copy runs. It is whether the copy replaces or adds.</text></svg>", "caption": "A faster mirror reaches the third column sooner. It does not reach a different answer."}
```

Read the third column. A **mirror** — a copy that is made identical each time it runs — reaches
the moment after the damage and faithfully replaces the good copy with the bad one. Running it
more often makes that happen sooner.

**Versioning** means the copy *adds* rather than replaces, and keeps the old states for some
period. That one property is what makes the difference, and it is a setting rather than a
different product: almost every backup tool has it and some ship with it off.

## How many versions, and for how long

There is no correct number and there is a shape that works:

| | keep |
|---|---|
| the last few days | every version |
| the last month | one a day |
| the last year | one a week |
| beyond that | one a month, if the data is worth it |

The reasoning is that recent mistakes are noticed quickly and old ones are noticed slowly. A
document you broke this morning wants this morning's version; a photograph corrupted two years
ago is discovered when you go looking for it, and one copy a month from that year is enough to
have something.

**The minimum that is worth calling a backup is thirty days of daily versions.** Under that, a
problem introduced on a Friday and noticed after a holiday is already the only copy.

## How often, honestly

| | who it suits |
|---|---|
| **continuously** | work you are actively writing, where an hour lost is an hour of work |
| **daily** | almost everybody, and it is what the tools default to |
| **weekly** | the external-drive copy, because it needs a human to plug it in |
| **monthly** | archives that do not change, and nothing else |

**Automatic beats frequent.** A weekly backup that happens is worth more than a daily one that
depends on remembering, and this is the reason the cloud copy is the one that survives contact
with real life.

## Full, incremental, differential

Three words on the settings screen, and one paragraph is enough:

- A **full** backup copies everything. Slow, large, and self-contained.
- An **incremental** copies what changed since the last backup of any kind. Fast and small, and
  a restore needs the full plus every increment since.
- A **differential** copies what changed since the last *full*. Middle-sized, and a restore needs
  only two pieces.

Modern tools mostly do incremental with occasional fulls and hide the whole thing, which is the
right default. The only reason to know the words is that **a long chain of increments is a long
chain of things that all have to be readable**, which is one more argument for the restore test.

## The one that is not about software

**Check that it ran.** Every backup tool can send a message or show a status, and every one of
them can also fail silently for months with the drive unplugged.

Once a month, look at the date of the newest backup. That is the whole of the maintenance, and
it is the step between *having a backup* and *having had a backup*.
