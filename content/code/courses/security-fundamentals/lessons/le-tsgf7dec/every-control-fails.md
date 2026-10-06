---
title: Every control fails sometimes
version: 1
---

The tempting way to secure something is to find the best control and put it in front: the strongest
password, the best firewall, the most expensive product. **That design has one point of failure,
and every control fails sometimes.** Passwords leak, rules are mistyped, software has bugs, people
click links. A plan that works only while one control is perfect is a plan for the day it is not.

**Defence in depth** is the opposite design: several controls in sequence, each able to stop what
got past the previous one, so that one failure does not become an incident. The idea is military
and old, a castle with a moat, a wall, a gate and a keep, and it carries over to information with
little change.

The picture most people use for it comes from accident investigation rather than from security:
James Reason's **Swiss cheese model**. Each layer of defence is a slice of cheese. Every slice has
holes, the weaknesses of that control, and the holes are in different places in each slice. An
accident happens only when the holes line up and something passes straight through all of them.

```schooling-figure
{"svg": "<svg id=\"sf-swiss-cheese\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The Swiss cheese model. Four slices stand in a row: login, permission check, file permissions and the log. Each has holes in different places. An arrow from the left passes through a hole in the first slice and is stopped by the second, whose hole is elsewhere. An incident needs the holes in every slice to line up.\"><defs><marker id=\"sf-swiss-cheese-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"188\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"188\" cy=\"140\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"188\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">login</text><rect x=\"300\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"318\" cy=\"100\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"318\" cy=\"160\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"318\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">permission check</text><rect x=\"430\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"448\" cy=\"70\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"448\" cy=\"120\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"448\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file permissions</text><rect x=\"560\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"578\" cy=\"150\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"578\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the log</text><text x=\"20\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a threat</text><path d=\"M20 60 L176 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M204 60 L292 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-swiss-cheese-ah-phosphor)\"></path><text x=\"318\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stopped by the second slice</text></svg>", "caption": "Every slice has holes. A threat gets through only where they line up."}
```

Two things follow from the picture, and both are practical.

**The holes do not have to be fixed for the defence to work.** A layer with a known weakness is
still useful if the next layer covers that weakness. A firewall that allows the web port will let
web attacks through; the application's own checks are what stops them. Neither layer is complete,
and together they cover more than either.

**What kills a defence is holes that line up**, and holes line up when layers share a cause. Two
controls that depend on the same password, the same administrator or the same piece of software
fail together, so they are one slice drawn twice. The last section of this lesson is about
spotting that.

A third, less obvious consequence is about time. A determined attacker has to find a hole in every
slice, and each slice takes effort. Even when they get through, the layers buy time, and time is
what detection needs: a log that notices the third failed step can stop the fourth. That is why
detection is a layer in its own right, and why lesson 11 is about getting it right.
