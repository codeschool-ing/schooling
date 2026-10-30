---
title: How review works, and how long it takes
version: 1
---

**A store review is a check that your release does what its listing says and breaks none of the
store's rules, made before the release reaches anybody.** It is not a test of your app's quality,
and passing it says nothing about whether the app is good. It does decide when people get it, so it
belongs in the release plan like any other step with a duration. *Read from Apple's App Review
pages, October 2026, and from Google's Play Console Help as published in 2025; not run.*

## Apple

Every new app and every update is reviewed, and Apple says that **App Review typically reviews at
least half of submissions in under 24 hours and 90% in under 48 hours.** A person installs the
build, signs in with the account you provide, and walks through it with the guidelines beside
them. A version can be submitted, approved and then released by hand or automatically; approval
and release are separate steps, which is what lets a team approve on Thursday and release on
Monday.

**An expedited review** can be requested for a critical bug fix or for an event tied to a date.
Apple asks for the steps to reproduce the bug, and grants it at its discretion. It is a favour, and
a team that asks for one every month stops getting them.

## Google

Google Play reviews new apps and updates with a mix of automated checks and people. Its help in
2025 warned that **a review can take up to seven days, and longer in some cases**, especially for a
new app or a new developer account; most updates to established apps go through much faster. Google
also checks the listing, the Data safety answers and the declared permissions, so a change to any
of those is reviewed too.

**Managed publishing** is Google's version of Apple's manual release: changes are reviewed, then
held until you press publish, so review time stops deciding launch time.

## What the clock means for a release

| what you plan | what to allow |
|---|---|
| an ordinary update, Apple | two days of review before the day you want it out |
| an ordinary update, Google | a few days, more for a new app or account |
| a launch on a fixed date | submit a week early, approve, and release by hand on the day |
| a fix for a crash in production | a staged rollout halted first, lesson 8, then an expedite request |

**The review clock runs again for every submission**, including the one that fixes a rejection. A
release rejected twice before passing has cost three reviews, which is why the next sections are
about not being rejected rather than about being rejected quickly.
