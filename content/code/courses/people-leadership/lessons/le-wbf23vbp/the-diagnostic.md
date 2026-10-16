---
title: A sequence of questions, before any conclusion
version: 1
---

Robert Mager and Peter Pipe wrote a short book in 1970, *Analyzing Performance Problems*, built around
a flowchart of questions a manager should ask before deciding what to do about somebody not
performing. **Its most famous question is a blunt one: could they do it if their life depended on
it?** If yes, the problem is not skill, and training will not fix it. If no, no amount of
encouragement will.

The sequence below adapts their idea for an engineering team. It is ordered so that the causes that
are the manager's responsibility come first, because those are the ones managers are least inclined to
look for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l19-diagnostic\" aria-label=\"Six questions in sequence, top to bottom. One: are the expectations clear? Two: do they have what they need? Three: could they do it if their life depended on it? Four: does anything reward doing it badly, or punish doing it well? Five: is something outside work getting in the way? Six, last: is it motivation? A bracket marks the first two as the manager’s own part.\"><defs><marker id=\"l19-diagnostic-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150.0\" y=\"20.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"198.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">are the expectations clear?</text><path d=\"M360.0 59.0 L360.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"70.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"198.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">do they have what they need?</text><path d=\"M360.0 109.0 L360.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"120.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"198.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">could they do it if their life depended on it?</text><path d=\"M360.0 159.0 L360.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"170.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"198.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">does anything reward doing it badly?</text><path d=\"M360.0 209.0 L360.0 219.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"220.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"198.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">is something outside work in the way?</text><path d=\"M360.0 259.0 L360.0 269.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"270.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"289.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"198.0\" y=\"289.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">only then: is it motivation?</text><path d=\"M138 22 L128 22 L128 106 L138 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120.0\" y=\"57.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the manager’s</text><text x=\"120.0\" y=\"70.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">own part</text><text x=\"584.0\" y=\"282.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the conclusion</text><text x=\"584.0\" y=\"295.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">managers reach first</text></svg>", "caption": "After Mager and Pipe. The order puts the causes a manager is least inclined to look for first."}
```

## 1. Are the expectations clear?

Does the person know what good looks like, in this role, for this work? Have they been told, in terms
they could repeat? A surprising share of performance problems are expectations that were never stated,
or stated once and contradicted since. **The test is to ask the person to describe what they think is
expected**, and compare it with what the manager thinks.

## 2. Do they have what they need?

Access, tools, information, time. A person waiting two weeks for access to a system, or working with a
test suite that fails at random, or carrying three projects when their manager thinks they have one, is
not underperforming; they are blocked. This is the environment question, and the manager is usually the
only person who can fix it.

## 3. Could they do it if their life depended on it?

Mager and Pipe's question. If the person has done this kind of work well before, the skill is there and
something else is in the way. If they never have, and the work needs it, the problem is skill, and the
response is training, pairing, or a different assignment.

## 4. Is there something that makes doing it well unrewarding, or doing it badly rewarding?

Mager and Pipe paid particular attention to this. Somebody who gets more work every time they finish
quickly has learnt to finish slowly. Somebody whose careful testing is never noticed, while a colleague's
fast, buggy releases are praised in demos, has learnt what the team values. **Consequences teach**, and
sometimes they teach the opposite of what the manager wants.

## 5. Is something outside work getting in the way?

Illness, a family crisis, caring for somebody, money worries, grief. A manager does not need, and often
should not have, the details. What they need to know is whether something is affecting the person's
capacity, so that the response is support rather than pressure. Lesson 5's rules about what gets
written apply here with full force.

## 6. Only then: is it motivation?

Motivation comes last, not because it never matters, but because it is the conclusion managers reach
first and most often wrongly. If the expectations were clear, the tools were there, the skill exists,
nothing rewards doing it badly and nothing outside work is in the way, and the work still is not being
done, then it may be a question of will. Even then, "why?" is the next question, and the answer is often
one of the earlier five in disguise.

## What Renata found

Working through the sequence before her next conversation with Marcos, Renata found two things she
could check herself. On expectations: nobody had told Marcos that the team expected to hear about being
stuck within a day or two; his previous manager had treated asking for help as a weakness, which lesson
5 had already hinted at. On the environment: the notification library he had been stuck on was
undocumented, and the only person who knew it had left Caju the year before. The other questions needed
him.
