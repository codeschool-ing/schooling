---
title: Nothing propagates
version: 1
---

You change a record. Somebody tells you it will take up to forty-eight hours to **propagate**.
That word is wrong, and believing it stops you from doing the one thing that would have made the
change fast.

Nothing spreads. Nothing is pushed anywhere. No server is told that you changed anything.

What actually happens is that resolvers around the world are holding an old answer, each for a
length of time **you** specified, and each one asks again when its own copy runs out.

## The number is on every record

Each record carries a **time to live** in seconds. It is an instruction to whoever receives the
answer: you may use this for this long.

```
www.example.com.   300   A   203.0.113.7
```

Three hundred: five minutes. A resolver that asks at 14:00 will answer from its own copy until
14:05 and then ask again. Change the record at 14:01 and that resolver serves the old address for
four more minutes — not because of distance, not because of propagation, but because you told it it
could.

## Which is why it appears for some people and not others

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Three resolvers hold the old answer, each having asked at a different moment. After the record changes, each one serves the old value until its own copy runs out, so the change appears at three different times.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the record changes at 14:01, with a TTL of five minutes</text> <rect x=\"20\" y=\"40\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">you make the change — and nobody is told</text> <rect x=\"20\" y=\"90\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"230\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolver A asked at 14:00 — old answer until 14:05</text> <text x=\"460\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new at 14:05</text> <rect x=\"20\" y=\"132\" width=\"560\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"300\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolver B asked at 14:03 — old answer until 14:08</text> <text x=\"600\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new at 14:08</text> <rect x=\"20\" y=\"174\" width=\"240\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolver C had nothing</text> <text x=\"280\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new immediately</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">not a wave moving outwards — a set of independent timers</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">and the longest anybody waits is one TTL, which is a number you chose</text> </svg>", "caption": "Three people see the change at three different moments, and none of it has anything to do with distance."}
```

Every resolver started its clock at a different moment: whenever the first person on that network
happened to ask. So their copies expire at different moments, spread across the whole TTL.

That is the real shape of the phenomenon people describe as propagation. It is not a wave moving
outwards. It is a set of independent timers, none of which you can see, all of which end within one
TTL of the change.

And it gives you the guarantee worth remembering: **the longest anybody waits is one TTL**, counted
from your change. Not forty-eight hours, unless forty-eight hours is what you set.

## So lower it before you move, not after

The playbook is three steps and it turns a day into a few minutes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three steps: lower the time to live at least one old TTL before the move, make the change so that every copy expires within a minute, then raise the time to live again afterwards.\"> <rect x=\"20\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the day before</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">lower the TTL to 60</text> <text x=\"128\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this change waits out the</text> <text x=\"128\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">old TTL, which is the point</text> <rect x=\"252\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the move</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">change the record</text> <text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every copy in the world</text> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">expires within a minute</text> <rect x=\"484\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">afterwards</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">put the TTL back up</text> <text x=\"592\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fewer questions, and a</text> <text x=\"592\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cushion if your servers fail</text> <text x=\"360\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the first box is the step everybody skips</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">and skipping it is the entire reason a move takes a day instead of a minute</text> </svg>", "caption": "Three steps. The one that costs nothing and is always left out is the first."}
```

**The day before**, lower the TTL on the records you are about to change — to sixty seconds, say.
This change is itself subject to the *old* TTL, which is why it has to happen at least that long in
advance. That is the step everybody skips, and skipping it is what makes the move slow.

**Make the change.** Now the world's copies expire within a minute of each other.

**Put the TTL back up** once you are satisfied, because a low TTL costs something: more questions to
your authoritative servers, and a shorter cushion if those servers ever become unreachable. A day
is a reasonable resting value for a record that rarely moves.

## The one you do not control

There is a TTL in this system that is not yours: the one the registry puts on your `NS` records at
the TLD servers. It is commonly a day or two, and it is why *changing nameservers* really does take
much longer than changing a record.

That is the true origin of the forty-eight-hour folklore. It is accurate for exactly one kind of
change — moving your whole domain to a different DNS provider — and it has been repeated ever since
about changes that take five minutes.

## A name that does not exist is cached too

This one surprises people, and it has a memorable shape.

When a resolver is told a name does not exist, it caches that too — that is **negative caching**,
and its length comes from a field in the domain's `SOA` record rather than from any TTL you set on
the record you are creating, because the record did not exist to carry one.

So: look up a name before you create it, and you may wait longer for it to appear than if you had
never asked. The nonexistence is in a cache, with a lifetime chosen by the domain's defaults, and
creating the record does not reach in and remove it.

The practical rule is the opposite of instinct: **do not keep checking a name you are about to
create.** Create it, then check.

## Choosing a number

A short summary, because this is a real decision and it is usually made by accident.

**Sixty seconds to five minutes** for anything you are actively moving, and for records in front of
a system that fails over by changing them.

**An hour to a day** for the ordinary case: a site that sits where it sits.

**A day or more** for records that genuinely never change, and for `MX` records in particular,
where the cushion during a DNS outage is worth more than the speed of a change you make once a
decade.

And one thing that is not a matter of taste: the TTL is a promise about the past as much as the
future. Whatever it says now is what somebody may still be using an hour from now, so the time to
think about it is before you need the change, and not during.
