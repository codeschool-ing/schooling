---
title: Three things a person feels
version: 1
---

**A person does not feel a page's load time. They feel three separate things: whether the page is
there yet, whether it answers when they touch it, and whether it holds still while they read it.**
Each one fails in its own way, and a page can be perfect at one and dreadful at another. A page that
shows its content in half a second and then ignores taps for two seconds is fast by one measure and
broken by the experience.

Google calls one number for each of those three the **Core Web Vitals**:

| what a person feels | the metric | what it measures |
|---|---|---|
| it is there | **LCP**, Largest Contentful Paint | when the largest piece of content in the window was painted |
| it answers | **INP**, Interaction to Next Paint | how long the slowest of the page's interactions took to show a response |
| it holds still | **CLS**, Cumulative Layout Shift | how much content moved without the person asking it to |

## Teach the feeling, cite the number

The three names and their thresholds belong to Google, which revises them. **INP replaced an older
metric, First Input Delay, in March 2024**, because FID measured only the wait before the first
interaction began, and a page could score well on it while every tap after the first took a
second to show anything. Whatever the metrics are called in five years, the three feelings will be
the same, so each section below starts with what a person notices and comes to the number second.
The thresholds this lesson quotes are the ones the `web-vitals` library encodes, at the version the
lesson installs, and the section "Good, needs improvement, poor" shows where to read them.

## Where these numbers come from

Every one of them is measured **in the browser**, by the browser's own performance APIs, while a
real page is used. The two other numbers this course has used so far are on the way to them:

- **first contentful paint**, from `look.ts` in lesson 1, is the first moment *anything* was drawn,
  and LCP is the moment the largest thing was;
- **the time the script took over**, from `hydrate.ts` in lesson 4, is part of what INP feels: a tap
  in the dead window is an interaction whose response cannot come until the script is there.

The rest of this lesson defines each metric precisely enough to reason about it, adds them to the
planner, breaks two of them on purpose and repairs them, and sends them home from the visitor's
browser, which is the only place they mean anything.
