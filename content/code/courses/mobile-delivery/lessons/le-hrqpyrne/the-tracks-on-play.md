---
title: The tracks on Google Play
version: 1
---

**Google Play gives every app four places to put a release, and a release in one of them reaches
a different group of people.** They are called **tracks**, and they form a ladder: the lower the
track, the fewer and more forgiving the people on it. *Read from Google's Play Console Help as
published in 2025, which the recording machine could not reach; not run.*

| track | who gets it | how they join | review |
|---|---|---|---|
| **internal testing** | up to 100 testers you name | an e-mail list, and an opt-in link | the fastest; available to testers within minutes of upload |
| **closed testing** | the groups or e-mail lists you choose | an opt-in link, or a Google Group | reviewed like a release |
| **open testing** | anybody who joins from the store page | a *Join the beta* button on the listing | reviewed like a release |
| **production** | everybody, or a percentage of everybody, lesson 8 | installing from the store | reviewed |

## Why four and not two

Each step widens the audience and changes what a bug costs. An internal build crashing costs a
colleague a minute; an open beta crashing costs reviews from strangers, which open testers can leave
privately and which still hurt. **The ladder exists so that the first person to meet a crash is
the cheapest one.** A team that uploads straight to production skips every rung and finds out from
the store's rating.

## The rule for a new personal account

Lesson 3 met it already: Google's help in 2025 required a new personal developer account to run a
**closed test with at least 12 testers for at least 14 days** before production access. For those
accounts the closed track is not optional; it is the gate.

## Testers on more than one track

A person can be a tester on several tracks at once, and on production as an ordinary user. **Google
Play gives them the release with the highest version code among the tracks they can see.** A
colleague on the internal track and the closed track gets whichever build is newer, which is
usually what you want, and is surprising the day the internal build is older than the closed one
and the colleague swears they are testing the fix. Section "One build, promoted" runs exactly that
case.
