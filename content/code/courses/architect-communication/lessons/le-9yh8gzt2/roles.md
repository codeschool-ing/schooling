---
title: Driver and navigator
version: 1
---

**Pair programming is two people working on one task at one screen, with one of them typing and the
other thinking ahead, and swapping often.** The picture most people have is a senior engineer watching
a junior type and correcting them, which is the least useful version and the one that gives pairing
its reputation for being exhausting.

## The two roles

- The **driver** has the keyboard and works on the line in front of them: the syntax, the next test,
  the name of this variable.
- The **navigator** works one level up: where this function is going, what the next three steps are,
  what could break, whether the test is testing the right thing. The navigator does not dictate
  keystrokes.

**They swap every fifteen to thirty minutes**, or at a natural point such as each passing test. A
pair that never swaps is one person programming and another watching, and the watcher's attention
drifts within minutes.

## Strong-style pairing

Llewellyn Falco, who teaches pairing and mob programming, describes a stricter version he calls
*strong-style* pairing, summed up in one rule: **"for an idea to go from your head into the computer,
it must go through someone else's hands."** The person with the idea navigates; the other person types.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three boxes left to right: the navigator, who has the idea and says it; the driver, who has the keyboard and types it; the code. Under them, Llewellyn Falco&#x27;s rule: for an idea to go from your head into the computer, it must go through someone else&#x27;s hands.\"><defs><marker id=\"strongstyl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">navigator</text><text x=\"115\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">has the idea,</text><text x=\"115\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">says it</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">driver</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">has the keyboard,</text><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">types it</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">the code</text><path d=\"M212 95 L262 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#strongstyl-ah)\"></path><path d=\"M457 95 L507 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#strongstyl-ah)\"></path><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">\"for an idea to go from your head into the computer, it must go through someone else's hands\"</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Llewellyn Falco</text></svg>", "caption": "Strong-style pairing. The person with the idea never types it, so a senior with an idea has to explain it well enough for the junior's hands."}
```

It sounds like a small change and it reverses the usual pattern. When the senior engineer has the idea,
the junior drives, so the junior's hands learn the change and the senior has to explain the idea well
enough for somebody else to type it. When the junior has an idea, the senior drives and has to follow
it, which is the fastest way for a senior person to hear an idea they would otherwise have overridden.

## Talking is the work

A silent pair is not pairing. The navigator thinks aloud ("I think we'll need the closing time here,
but let's get the test passing first"), and the driver says what they are doing when it is not
obvious. **The conversation is where the knowledge transfer happens**, which is the same finding as
lesson 11's review study, in real time instead of in comments.

That also explains why pairing is tiring. Two people concentrating aloud for two hours is more effort
than one person concentrating quietly, and pairs who try to pair for eight hours a day burn out. Most
teams that pair well do it for a few hours a day, with breaks, and not on every task.
