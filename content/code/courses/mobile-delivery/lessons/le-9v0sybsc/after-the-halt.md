---
title: What a halt does, and what it does not
version: 1
---

**Halting a rollout stops the bad version reaching anybody new. It does nothing for the people who
already have it.** In the simulation, 1011 installs keep 1.5.0 after the halt, and each of them
keeps crashing until a version that does not crash reaches them. The halt is the first move of an
incident, not the end of it.

## The sequence, from the halt to the fix

1. **Halt** the rollout on Google Play, **pause** the phased release on the App Store.
2. **Find the cause** in the crash reports, grouped by version and by device. Lesson 13 reads the
   stack traces; lesson 14 deals with the freezes that are not crashes.
3. **Build 1.5.1** with the fix, or with 1.4.0's code, and a higher version code.
4. **Release 1.5.1 fast**: an expedited review on Apple's side, lesson 6, and a rollout that can
   move quickly because it is the cure. Its first stage goes to the people who have 1.5.0.
5. **Resume the rollout with 1.5.1**, not with 1.5.0.

## The people already on the bad version

On Google Play, a halted release stays installed where it is. On the App Store, people who updated
by hand during the phased release have it too. **Nothing in either store reaches into a phone and
replaces a version.** What reaches them is the next update, which arrives only when the phone
updates, and many phones update apps only on Wi-Fi and power, or not automatically at all.

That is why lesson 19 exists. A **remote switch**, read by the app at start-up, can turn the broken
feature off on the 1011 phones within minutes, if it was built in before 1.5.0 shipped. A **forced
update** screen can ask people on 1.5.0 to update once 1.5.1 is out. Neither can be added after the
fact to the version that is already broken.

## The one rule to keep

**Every release that reaches production is staged, every one, including the small ones.** The bug in
1.5.0 was in a change somebody called trivial. A rollout that would have gone straight to 100% would
have put it on twenty thousand phones by the evening; the staged one put it on 1011, and stopped.
