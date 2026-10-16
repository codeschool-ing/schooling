---
title: What a test on a bad network should assert
version: 1
---

**A test on a bad network is not testing whether the request succeeds. It was built so that it
would not.** It tests what the person is shown while it fails and what the server holds
afterwards. Asserting `200` through a proxy that drops answers produces a test that fails whenever
a drop lands on it, and teaches nothing. Asserting the screen and the seats produces a test that
holds whichever answers are lost.

## The cases, and what each must show

| case | assert | where this lesson or an earlier one checks it |
|---|---|---|
| **no network, a saved copy** | the copy is on screen, and the banner says it is a copy and from when | lesson 16's `OfflineTest` |
| **no network, nothing saved** | the error line, which says what to do: *Check the connection and press Refresh* | lesson 16's `OfflineTest` |
| **slow, inside the limit** | a fresh list and no banner | `SlowNetworkTest`, section 05 |
| **slow, past the limit** | the saved copy, labelled | `SlowNetworkTest`, section 05 |
| **an answer lost after a purchase** | one order on the server, read from the server itself | `tests/poor-network.test.mjs`, section 04 |
| **the network comes back** | Refresh brings a fresh list and the banner goes away | below |
| **the wait** | how long the screen can sit unchanged, and what it shows meanwhile | a number to agree, below |

## When the network comes back

**Recovery is the case most often left out**, because the failure has been tested and the test
ends there. In Tickets it is a button. `display` hides the banner and the error line first, on line 50 of
lesson 14's `MainActivity`, so a fresh load after an offline one should leave neither. A third
test for `SlowNetworkTest` checks it with the slow proxy and boxoffice itself. Adding it to the
class is yours:

```kotlin
Shows.baseUrl = SLOWER_THAN_THE_TIMEOUT
onView(withId(R.id.refresh)).perform(click())
onView(withId(R.id.banner)).check(matches(isDisplayed()))
Shows.baseUrl = boxoffice
onView(withId(R.id.refresh)).perform(click())
onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
```

Nothing in Tickets refreshes on its own when the network returns. The person has to press the
button. Whether it should is a product question, and the honest test asserts what the app promises
today.

## The wait a person can bear

**There is no correct number of seconds**, and a test plan that pretends there is has borrowed one.
What a tester can do is measure the worst case and put it in front of the people who decide.
Tickets's is longer than its two five-second limits suggest. A connection accepted in four seconds
and then silent for four more takes eight. An answer trickling in slower than one piece every five
seconds never times out at all. During all of it, section 05 found, the screen shows nothing to say
it is waiting. **"The screen says something within a second" is a better assertion than any
timeout**, and it is the one Tickets would fail today.

## What not to assert

- Exact durations. A request through `DELAY=800` takes a little over 800 ms, never exactly.
  Assert a window, as lesson 13 did for the payment timeout: at least the delay, and well under the
  next limit.
- Which request is lost, unless the test fixed the seed. With `SEED` set, the proxy loses the
  same answers every run, which is what lets `poor-network.test.mjs` expect a replay. With a random
  seed, assert only what holds whichever requests are lost, which is the seat count.
- That Android says the phone is offline. Section 02's café Wi-Fi is connected and useless. The
  app has to cope with what its requests do, not with what the status bar shows.

## What this lesson found

Four things for the report, each with the evidence it rests on. Two come from the runs. **A slow
link to the payment provider charges a customer for an order boxoffice calls failed**, which is
lesson 13's defect reached without a slow provider. **A client that retries a purchase without an
idempotency key buys a ticket for every lost answer**, and that belongs in the client team's report
rather than boxoffice's. Two come from Tickets's code, to be confirmed on your emulator: no sign of a
load in progress, and "Offline" shown for a network that is only slow.
