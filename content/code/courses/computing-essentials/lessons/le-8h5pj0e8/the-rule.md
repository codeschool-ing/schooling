---
title: Three, two, one, which is a rule and not a slogan
version: 1
---

The arrangement that answers all four rows is old, short and worth memorising: **three copies, on
two kinds of media, with one of them somewhere else.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 314\" role=\"img\" aria-label=\"Three boxes joined left to right. The first is the working copy, on the machine itself. The second is the first backup, on an external drive in the same room. The third is the second backup, on a service somewhere else. Below them three numbered lines give the reason for each number: three copies so no single loss is the last one, two kinds of media so one failure mode cannot take both, and one somewhere else so the room is not the boundary.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Three, two, one, and what each number is for</text><rect x=\"24\" y=\"48\" width=\"190\" height=\"86\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"119\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the working copy</text><text x=\"119\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">on the machine</text><path d=\"M220 91 L248 91 M240 86 L248 91 L240 96\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"254\" y=\"48\" width=\"190\" height=\"86\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"349\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the first backup</text><text x=\"349\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an external drive</text><path d=\"M450 91 L478 91 M470 86 L478 91 L470 96\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"484\" y=\"48\" width=\"190\" height=\"86\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"579\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the second backup</text><text x=\"579\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a service somewhere else</text><rect x=\"24\" y=\"176\" width=\"672\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"44\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">3</text><text x=\"72\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copies, so that no single loss is the last one</text><rect x=\"24\" y=\"210\" width=\"672\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"44\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2</text><text x=\"72\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">kinds of media, so that one failure mode cannot take both</text><rect x=\"24\" y=\"244\" width=\"672\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"44\" y=\"258\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"72\" y=\"258\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">of them somewhere else, so that the room is not the boundary</text><text x=\"24\" y=\"296\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Most people have one and a half of these, and the half is a sync service they have not checked.</text></svg>", "caption": "The numbers are not a slogan. Each one closes a row of the grid above, and dropping any of them reopens it."}
```

Read each number as the row of the grid it closes.

**Three copies** — the original and two backups. Two is not enough because a restore is the
moment you discover the backup was broken, and at that point the original is already gone. The
third copy is what makes a failed restore an inconvenience rather than the end.

**Two kinds of media** — not two folders on the same drive, and not two drives of the same model
bought on the same day. A batch of drives fails at similar ages. An external drive and a cloud
service are two different failure modes, which is the property that matters.

**One somewhere else** — because rows three is a *place* failing, not a device. An external drive
in the drawer under the machine is in the same fire, the same flood and the same burglary.

## What this looks like in an ordinary house

| copy | where | answers |
|---|---|---|
| the original | the machine | nothing. It is what you are protecting |
| an external drive | a drawer, connected weekly | deletion, drive failure, ransomware |
| a cloud backup | a service, automatic | theft, fire, flood |

That is three copies, two media, one offsite, and it costs an external drive and a few dollars a
month. **It is also the arrangement almost nobody has**, because the middle row needs a habit and
the bottom row needs a decision.

## Three near-misses worth recognising

- **Two folders on one drive.** One copy, dressed as two. Everything fails together.
- **A sync service alone.** Two locations and one *state* — the thing you are trying to survive
  is a change, and a change is copied.
- **An external drive left plugged in.** It answers drive failure, and ransomware encrypts it
  along with everything else, because to the machine it is just another folder.

The last one is worth the extra sentence. **A backup drive that is always connected is part of
the machine.** Unplugging it between backups is free and it converts row four from *perhaps* to
*survives*.

## And the cheap version, if the full rule is too much

If you do one thing from this lesson: **an external drive, connected once a week, with
versioning on, unplugged in between, and stored somewhere other than on the desk.** That is two
copies and one medium and it is not the rule — and it answers three of the four rows, which is
three more than most people manage.
