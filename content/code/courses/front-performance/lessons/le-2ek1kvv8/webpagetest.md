---
title: WebPageTest
version: 1
---

**WebPageTest loads your page from a real browser somewhere else in the world**, on a connection you
choose, and reports the load in more detail than any other tool: a waterfall of every request, a film
strip of what the window showed as the page loaded, a video, and the Core Web Vitals of that load.
It began as an open-source project, is run today by Catchpoint at webpagetest.org, and its code is
still public for anybody who wants to run their own.

**This course did not run it**, and the section says so plainly: WebPageTest loads the page from its
own machines, so it can only test a page on a public address, and everything in this course runs on
your computer. What follows is what its documentation describes. Use it on the first page you put on
the internet; the terms of the public service are Catchpoint's, and they set and change them.

## What it adds to the other two

- **A location and a real network.** A test runs from a city you pick, on a connection profile such
  as cable or 4G, so the round trips are real round trips across the internet, not 300 milliseconds
  added on one computer.
- **Several runs, and the median.** A test usually loads the page more than once and reports the
  median run, for the reason the section "Simulated, or slowed for real" gave.
- **First view and repeat view.** The second load of a test runs with the cache the first one filled,
  which is the visit of somebody coming back, and the one lesson 9 makes fast.
- **The film strip.** A row of frames, at an interval you choose, lined up with the waterfall. It is
  the clearest way to show somebody else what a slow load looks like, and to see that an LCP of three
  seconds was a blank screen for two of them.

## When to reach for which

**Lighthouse to notice, the panel to explain, WebPageTest to see a real first visit from far away.**
A problem usually goes through them in that order: a score drops in Lighthouse, the panel shows the
long task or the late request behind it, and WebPageTest confirms what a visitor in another country,
on a slow phone network, actually waits through. And all three are lab data: the field data of lesson
5 is what says whether the fix mattered to the people using the page.
