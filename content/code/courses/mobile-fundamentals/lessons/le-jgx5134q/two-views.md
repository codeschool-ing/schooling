---
title: What the user sees, and what the system sees
version: 1
---

**On a phone, an app does not run from the moment it opens until the moment it is closed; the
system moves it between states, and it can take the process away whenever it decides to.** The
picture most people bring from a laptop is two states: the program is open, or it has been quit.
A user of a phone holds the same picture, and it is wrong in a way that matters to whoever writes
the app.

## What the user thinks happened

From the user's side there are three situations, and none of them feels like a decision:

- the app is **on the screen**, and they are using it;
- the app is **somewhere behind**, in the list of recent apps, and they expect to find it exactly as
  they left it;
- the app was **closed**, because they swiped it away.

**The second is the one the user trusts and the system does not keep.** The app the user sees in
the recent list may still be in memory, may be frozen in memory, or may have no process at all
because the system killed it an hour ago to make room for a game. The recent list shows a picture of
the screen in every one of those cases, and the user cannot tell them apart.

## What the system knows

The system tracks more than that, and it tracks it per app. Android and iOS name the states
differently and draw the lines in slightly different places, but both distinguish the same five
situations, which this course uses as one model:

| state in this course | what is true |
|---|---|
| **active** | on screen, in front, receiving the user's touches |
| **inactive** | still visible, but something is in front of it: a call, a system panel, a dialog |
| **background** | not visible; the code may still run, briefly |
| **suspended** | in memory but not running; nothing the app wrote executes |
| **not running** | no process: never started, or killed |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l04-states\" aria-label=\"The five states of the shared lifecycle and the moves between them. Not running leads by launch to active. Active and inactive move into each other by interrupt and resume. Inactive leads by leave to background. Background leads by suspend to suspended. Background and suspended both lead by return to active. Background and suspended both lead by kill to not running, and no platform calls the app when that happens. Each state also carries its names: active is Android resumed, iOS .active, React Native active; inactive is paused, .inactive, inactive on iOS only; background is stopped, .background, background; suspended is a cached process on Android, suspended on iOS, and nothing in React Native.\"><defs><marker id=\"l04-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">not running</text><text x=\"90.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no process</text><rect x=\"220\" y=\"40\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">active</text><text x=\"300.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: resumed</text><text x=\"300.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .active</text><text x=\"300.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: active</text><rect x=\"430\" y=\"40\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">inactive</text><text x=\"510.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: paused</text><text x=\"510.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .inactive</text><text x=\"510.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: inactive (iOS)</text><rect x=\"430\" y=\"180\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">background</text><text x=\"510.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: stopped</text><text x=\"510.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .background</text><text x=\"510.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: background</text><rect x=\"220\" y=\"180\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">suspended</text><text x=\"300.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: cached process</text><text x=\"300.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: suspended</text><text x=\"300.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: nothing</text><path d=\"M170 70 L218 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"195\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">launch</text><path d=\"M380 58 L428 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">interrupt</text><path d=\"M430 88 L382 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">resume</text><path d=\"M510 106 L510 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"518\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">leave</text><path d=\"M430 205 L382 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">suspend</text><path d=\"M300 180 L300 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><path d=\"M440 180 L372 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"306\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">return</text><path d=\"M220 225 L90 225 L90 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-states-ah-amber)\"></path><path d=\"M510 246 L510 262 L70 262 L70 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-states-ah-amber)\"></path><text x=\"300\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">kill: no callback on any platform</text></svg>", "caption": "One model, three vocabularies. The two dashed arrows are the ones no platform announces: the app is not told it was frozen, and not told it was killed."}
```

**Two arrows in that figure carry no name of any callback**, and they are the reason this lesson
exists. Moving from background to suspended happens without telling the app on either platform, and
so does being killed from background or suspended. The app is running code one moment and has no
process the next.

## Why the system does it

**Memory, and the battery.** A phone has far less memory than the apps on it would use if they all
stayed alive, and every running process spends battery. So the system keeps the app in front
running, lets the ones behind it finish briefly, freezes them, and reclaims their memory when
something else needs it. Android's documentation says that the system "kills processes when it needs
to free up RAM", and that the likelihood depends on the state: lowest for the app in the foreground,
highest for a process with nothing visible. Apple's says that the system "terminates background apps
as needed" to make memory and other resources available to the foreground.

**The user did not do it, so the user expects nothing to have changed.** That is the whole
difficulty. A process killed while the user was on a call is, from the user's side, the same app
they left twenty minutes ago, and they expect the same screen with the same half-typed text.
Lesson 5 is about giving it back to them. This lesson is about knowing when it can be taken away.
