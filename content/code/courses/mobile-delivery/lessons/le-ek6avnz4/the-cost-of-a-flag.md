---
title: The cost of a flag
version: 1
---

**Every flag doubles the number of ways the app can be, and a flag nobody removes stays forever.** Two
flags make four combinations, ten make a thousand, and nobody tests a thousand. Flags are cheap to add
and expensive to keep, which is why the useful ones have an end date from the day they are added.

## Three kinds, with three lifetimes

| kind | example in the planner | how long it should live |
|---|---|---|
| **release flag** | `statistics`, while the screen rolls out | until it reaches 100%; then the flag and the old code path are deleted |
| **kill switch** | turning sync off if the server is overloaded | permanently, but there are very few of them, and each is tested |
| **experiment** | two layouts of the first screen, lesson 17 | until the experiment has its answer, lesson 18's sample |

A release flag still in the code six months after reaching 100% is debt: a branch nobody takes, which
somebody one day flips by accident. The usual rule is a **ticket to remove the flag**, created in the
same pull request that adds it.

## Testing with flags

- **Test both sides of every live flag** in the automated tests, with the flag forced on and forced off.
- **Test the defaults**: the app with no server and no cache, which is what a new installation on a bad
  network meets first.
- **Never test only the combination that is on in production today**; tomorrow's is different.

## The same on three platforms

Every platform has the same products for this: **Firebase Remote Config** for Android, iOS and React
Native; **LaunchDarkly**, **ConfigCat**, **Unleash** and others, some of which run on your own
servers. They add targeting, dashboards and audit logs. What they do not change is this lesson's
logic: a cached copy, safe defaults, stable buckets, and a flag that is removed when its work is done.
*None of these products was set up for this course.*
