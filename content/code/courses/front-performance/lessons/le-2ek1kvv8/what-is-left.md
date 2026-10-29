---
title: What the report still says
version: 1
---

**The score is a hundred and the report still lists three insights.** They were there on the
three-course page too, and none of them is worth a point at this size. Each is worth understanding,
because on a bigger page each one is:

| insight | what it found | where it is fixed |
|---|---|---|
| **Render-blocking requests** | the stylesheet: the browser will not paint until it has it, so it costs a round trip before the first paint | lesson 7, which inlines the CSS the first screen needs |
| **Use efficient cache lifetimes** | the script and the stylesheet are sent with no cache lifetime, so a second visit asks for them again | lesson 9, cache headers |
| **Network dependency tree** | the chain of requests: the HTML, then the files it names | the section "Waterfalls", in this lesson |

## Reading an estimated saving

**An estimated saving is a model's answer to "what if this were gone"**, in milliseconds or in
kilobytes. It is useful for ranking, and it is not a promise: the 150 milliseconds for the stylesheet
assume a slow phone on a slow network, and they would not all turn into LCP, because the HTML has to
arrive anyway. Fix the biggest saving first, measure, and read the report again; an insight sometimes
disappears because a bigger one was fixed.

## When to stop

**Not every insight is worth its fix.** A stylesheet of under half a kilobyte, on a page whose LCP is a
second, is a finding to note and leave; inlining it is a build change that has to be maintained. The
score is a way of noticing, and a hundred is not the goal. The goal is the three numbers of lesson 5,
for real visitors, and an insight earns its fix when it moves one of them.

And one finding is in no insight at all: **the plan of five thousand courses is still in every page**,
compressed now, but parsed by every visitor who opens a course. It is not a setting to turn but a
decision about what the page needs, and lesson 8, on loading on demand, is where it gets made.
