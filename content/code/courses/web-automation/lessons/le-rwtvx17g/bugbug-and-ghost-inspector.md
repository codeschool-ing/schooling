---
title: "BugBug and Ghost Inspector: the recording as a service"
version: 1
---

Selenium IDE leaves you with a file. **BugBug and Ghost Inspector leave you with an account.** Each
one records through a browser extension, keeps the tests on its own servers, replays them on its own
browsers, on a schedule, and tells you when one fails. What you buy is the machinery around the
recording, more than the recording itself.

**Neither was used for this course, and their sites could not even be opened from the machine these
lessons were written on.** What this section says about each one is what its own documentation
pages say, as a search engine's index returned them in October 2026. Every feature below is the
vendor's claim, not something tested here. Both sell plans, the plans have prices, and the prices
and what each plan includes change; read them on the vendor's site on the day you decide, and
never from a course.

## BugBug

Its quick-start guide begins with the extension: install BugBug's extension for Chrome from the
Chrome Web Store and allow it in incognito mode, so that recordings run in a clean browser profile.
That is the first lesson of lesson 4 arriving through a setup screen: a browser full of your own
cookies and cache is a different browser from the one your users have.

Its documentation on schedules says the service can run tests "in the cloud" automatically and
send an e-mail about the failed ones. Two details on those pages matter more than the headline:

- **Only a suite can be scheduled, never a single test.** The schedule is the unit of monitoring,
  and the suite is what it watches.
- **A suite can retry a failed test**, and a test that passes on a later attempt marks the suite as
  passed, with the failed attempt kept in the history as "auto-retried". That is exactly the retry
  lesson 14 warns about: green on the dashboard, a flaky test underneath, and the evidence one click
  away for anybody who goes looking.

Its best-practice page adds the network's side: an application behind a firewall may have to allow
the service's runners by address, or the tests fail on a door, not on the shop.

## Ghost Inspector

Its documentation describes the same loop. The extension records a walk through your application;
the saved test runs once in Ghost Inspector's own browser; then its steps and settings can be edited
in the service.

**Two of its recorder settings are aimed straight at this course's lesson 2.** The recorder can be
told to ignore particular attributes or class names, and an application with dynamic ids can switch
matching by id off, so a recording falls back to other ways of naming an element. That is a vendor
admitting, in its own settings page, that a recorder left alone picks names like `#card-4821`. The
setting fixes the next recording; the ones already saved keep the names they were given.

The rest of what its pages describe is monitoring:

- **a schedule per test or per suite**, with a test taking its suite's schedule unless given its
  own;
- **a screenshot comparison** at the end of a run, against the last passing screenshot, with a
  tolerance stated as a share of the pixels that may change. Lesson 16 does the same thing with
  Playwright's `toHaveScreenshot`, and the same trade-off applies: too tight and every font update
  fails, too loose and a missing button passes;
- **an import of Selenium's HTML format**, the format of the IDE before `.side` files, announced on
  its blog.

## What the model gives, and what it takes

**It gives you no infrastructure to run.** There are no browsers to install, no CI job to write and
no machine to keep awake at three in the morning. A scheduled run against the live site every few
minutes is monitoring more than testing: a smoke check, in `manual-testing` lesson 8's sense,
repeated by a machine.

**It takes the tests out of your repository.** They live in the vendor's account, edited in the
vendor's editor, so a change to a test does not travel in the same pull request as the change to the
application that made it necessary, and nobody reviews the two side by side. Ask three questions
before the first recording, not after the hundredth:

1. **Can the tests leave?** In what format, and does that format still run anywhere else.
2. **What does the vendor's browser hold?** A test that signs in keeps a password in somebody else's
   service. Give it a test account that can do only what the test needs, and nothing a real
   customer owns.
3. **Which environment does it hit?** A recording that adds to a basket against production adds to
   a real basket. Lesson 15 is about the data a test leaves behind; a schedule repeats it every few
   minutes.

None of these is a reason not to use a service. They are the reasons the next sections run the
recordings and count what changing them costs.
