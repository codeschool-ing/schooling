---
title: Three tools, three questions
version: 1
---

**Lesson 5 gave a page three numbers. This one is about the tools that say why a number is what it
is.** Each of the three answers a different question, and a performance problem usually needs all
three in turn:

| tool | what it does | the question it answers |
|---|---|---|
| **Lighthouse** | loads a page once, under conditions it chooses, and grades what happened | what is wrong with this page, roughly, and where should I look first? |
| **the performance panel** | records everything the browser's main thread did while you used the page | what exactly was the browser doing during those slow 800 milliseconds? |
| **WebPageTest** | loads the page in a real browser somewhere else, on a network you pick, several times | what does a first visit from far away, on a slow connection, look like? |

All three produce **lab data**, in the sense of lesson 5's section "Field data: the number from the
visitor": one browser, conditions somebody chose, a measurement you can repeat. None of them knows
how the page behaves for its real visitors. Lighthouse and the panel run on your computer; WebPageTest
runs on somebody else's, which is its whole point and also why it needs the page on a public address.

## Where you have met them already

**Lighthouse is in Chrome's developer tools**, in a tab of its own, and on the command line, which is
how this lesson runs it, because a command can be repeated and its output read by a program.
**PageSpeed Insights**, Google's page at pagespeed.web.dev, is Lighthouse run from Google's servers
with the field data of CrUX shown above it, for a page on the internet: the lab and the field on one
screen, which is the clearest way to see that they disagree.

**The performance panel is the Performance tab** of the same developer tools, in Chrome and in every
browser built on Chromium, such as Edge. Firefox and Safari have their own profilers that answer the
same question with a different file format; this lesson records the Chromium kind, because that is
the browser it already drives.

## What this lesson measures

The planner, on your computer, with the same tools as before. Lighthouse first, on the course page
and then on a home page of five thousand courses, where it finds something worth fixing. Then a
trace of the main thread, read by a short program and opened in the panel. Then a **waterfall**, the
chart all three tools draw of the page's requests along time. WebPageTest last, described rather than
run, because it needs an address on the internet and this course keeps everything on your own machine.
