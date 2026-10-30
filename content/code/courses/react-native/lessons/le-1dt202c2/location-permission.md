---
title: Foreground or background, precise or approximate
version: 1
---

**Location is the permission people refuse most, and they are right to think about it.** A list of where
somebody was, and when, says where they live, where they work, whom they visit and when they are not at
home. So both platforms split the question into two separate choices, and the person makes each one.

## When: while the app is in use, or always

- **Foreground**, "while using the app": the app gets positions while it is on screen, and for a short
  while after. This is what most apps need, and the planner asks for nothing more.
- **Background**, "always": the app gets positions while it is closed. Both platforms ask for it as a
  second, separate step, after foreground was granted, and both stores ask the developer to justify it.
  The last section of this lesson is about it.

## How precisely: to the metre, or to the neighbourhood

- **Android 12 and later** show a choice in the dialog itself: *precise* or *approximate*. Approximate
  is a position to within a few kilometres, and the app is told which it got.
- **iOS** has a *Precise Location* switch in the same dialog, and an app can ask for *reduced accuracy*
  from the start, in which case the switch arrives off.

**The planner asks for approximate, and then makes it coarser still.** It needs to know that two
sessions were done in the same place, not which desk. It rounds every position to two decimal places,
about a kilometre, before the journal sees it, so the journal never contains anything more precise than
a district, whatever the phone handed over. That is the strongest privacy rule there is: **what is never
stored cannot leak.**

## When to ask

As in lesson 13, at the moment it is needed. For the planner, that moment is when the person turns on a
switch labelled *Note where I study* on *This week*. Turning it on asks; a refusal leaves it off and says
what that means; and while it is off, the planner never touches location at all.
