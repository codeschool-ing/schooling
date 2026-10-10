---
title: Three formats, and what each one actually measures
version: 1
---

Every engineering hiring process has to answer one question somewhere: can this person write and
reason about code at the level the job needs? **Three formats dominate, and each measures something
slightly different from the others, including things that are not the job.** Choosing one is choosing
what you are willing to measure by accident.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-formats\" aria-label=\"Three columns, one per format, each split into what it measures well and what else it measures. Take-home: well, how the person writes code with time to think; also, how much free time they have. Pairing: well, how they work on code with somebody else; also, comfort with being observed. Live coding: well, producing code quickly from a cold start; also, performance under pressure and practice at this style of problem.\"><text x=\"130.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">take-home</text><rect x=\"30.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">measures well</text><text x=\"130.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">code written with</text><text x=\"130.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">time to think</text><rect x=\"30.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">also measures</text><text x=\"130.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">how much free</text><text x=\"130.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">time they have</text><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">pairing</text><rect x=\"260.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">measures well</text><text x=\"360.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">working on code</text><text x=\"360.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">with somebody else</text><rect x=\"260.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">also measures</text><text x=\"360.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">comfort with</text><text x=\"360.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">being observed</text><text x=\"590.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">live coding</text><rect x=\"490.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">measures well</text><text x=\"590.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">code fast from</text><text x=\"590.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cold start</text><rect x=\"490.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">also measures</text><text x=\"590.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pressure, and practice</text><text x=\"590.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">at this kind of puzzle</text><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">every format measures something besides the job</text></svg>", "caption": "Choosing a format is choosing which incidental thing you are willing to measure."}
```

## The take-home

The candidate gets a small problem and works on it at home, in their own environment, usually with a
suggested time limit. They submit code, and sometimes discuss it in a follow-up conversation.

**What it measures well:** how the person writes code when nobody is watching and they have time to
think: structure, tests, naming, the decisions they make and write down. It is the closest of the three
to how most engineering work is actually done.

**What else it measures:** how much free time the candidate has. A four-hour exercise is four hours
taken from somebody's evenings or weekend, and that cost falls hardest on people with caring
responsibilities or a demanding current job. Candidates also spend far longer than the suggested
limit, because they know others will, which turns a "two-hour" exercise into a competition in unpaid
work. And it cannot tell you for certain who wrote the code.

## Pair programming

The candidate and an engineer from the team work together on a realistic problem for an hour or so,
on a shared screen. The interviewer participates rather than only watching: answers questions,
suggests, takes the keyboard sometimes.

**What it measures well:** how the person works with somebody else on code. How they ask questions,
how they respond to a suggestion, whether they explain their thinking, how they get unstuck. Much of
the job is exactly this.

**What else it measures:** comfort with being observed, which varies more than skill does. And it
depends heavily on the interviewer, who can make the hour collaborative or turn it into a test with an
audience.

## Live coding

The candidate solves a problem while the interviewer watches, often on a whiteboard or in a bare
editor, sometimes against the clock, usually without the tools they would use at work.

**What it measures well:** the ability to produce working code quickly from a cold start, in a
narrow kind of problem.

**What else it measures:** performance under observation and pressure, familiarity with the style of
problem (which can be practised for its own sake), and anxiety. A candidate who freezes in front of a
stranger may be an excellent engineer at a desk. **Of the three, it is the furthest from how the job is
done**, and the one where the incidental measurements are largest.

## None is neutral

Every format measures something besides the job. That is not a reason to avoid them; it is a reason
to know which incidental thing you are choosing to measure, and to reduce it where you can. The next
section is about how Caju chose, and the one after about making whichever format you use fairer.
