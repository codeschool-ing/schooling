---
title: Exponential backoff, and why it needs jitter
version: 1
---

**Wait longer after each failure, doubling the wait up to a ceiling, and choose a random point below
that ceiling rather than the ceiling itself.** The doubling is **exponential backoff**. The random
point is **jitter**, and the version where the wait is anywhere from zero to the ceiling is called
**full jitter**. Both exist for the server's sake more than the client's.

The common picture is that backoff is politeness: one client easing off so as not to annoy the
server. One client is not the problem. A server that went down for a minute comes back to every
phone that tried during that minute, and **if they all wait the same time, they all come back in
the same millisecond**. That is a second outage caused by the recovery from the first, and it has a
name: the thundering herd.

## Three phones after one outage

`backoff.ts` has the two formulas. `ceiling` doubles from `base` up to `cap`; `fullJitter` picks a
random number below the ceiling, from a generator seeded so the numbers repeat. This program asks
three phones, seeds 1, 2 and 3, what they would wait on each attempt, beside the ceiling a phone
with no jitter would wait. Save it as `schedule.ts`:

```typescript
// schedule.ts: the waits three phones would choose after the same outage, with and without jitter.
import { seeded, ceiling, fullJitter } from "./backoff.ts";

const BASE = 1000, CAP = 60_000; // milliseconds
const phones = [1, 2, 3].map(seeded);
console.log("attempt  no jitter   phone 1   phone 2   phone 3");
for (let attempt = 1; attempt <= 8; attempt++) {
  const waits = phones.map((random) => fullJitter(attempt, BASE, CAP, random));
  console.log([attempt, ceiling(attempt, BASE, CAP), ...waits].map((n) => String(n).padStart(8)).join("  "));
}
```

```
ana@dev:~/planner/retry$ node schedule.ts
attempt  no jitter   phone 1   phone 2   phone 3
       1      1000       627       734       720
       2      2000         5       649        77
       3      4000      2109      1141      1824
       4      8000      7848      4303       599
       5     16000     15494     14004     12208
       6     32000      8995     20186     15397
       7     60000     36770     29952     29203
       8     60000     43244     21434      9708
```

The `no jitter` column is what every phone waits, so every phone's second try lands at one second,
its third at three, its fourth at seven. With full jitter, the three phones scatter. At attempt 4
they wait 7848, 4303 and 599 milliseconds, more than seven seconds apart, and with a thousand phones
the requests spread across the whole window instead of arriving as one spike. The figure puts the
first four tries of each on one line of time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l09-herd\" aria-label=\"A time line from 0 to 16 seconds after an outage. With no jitter, every phone tries again at 1, 3, 7 and 15 seconds, all together. With full jitter, phone 1 tries at 0.6, 0.6, 2.7 and 10.6 seconds, phone 2 at 0.7, 1.4, 2.5 and 6.8, and phone 3 at 0.7, 0.8, 2.6 and 3.2: the same phones, spread out.\"><path d=\"M170.0 30 L170.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"170.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M236.0 30 L236.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"236.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><path d=\"M302.0 30 L302.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"302.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><path d=\"M368.0 30 L368.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"368.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><path d=\"M434.0 30 L434.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"434.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><path d=\"M500.0 30 L500.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"500.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M566.0 30 L566.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"566.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><path d=\"M632.0 30 L632.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"632.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><path d=\"M698.0 30 L698.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"698.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16</text><text x=\"434.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">seconds after the outage</text><text x=\"160\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no jitter: every phone</text><rect x=\"199.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"265.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"397.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"661.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">phone 1</text><rect x=\"186.7\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"186.9\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"256.5\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"515.4\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">phone 2</text><rect x=\"190.2\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"211.6\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"249.3\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"391.3\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">phone 3</text><rect x=\"189.8\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"192.3\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"252.5\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"272.3\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect></svg>", "caption": "The same four retries, from the waits schedule.ts printed. Without jitter every phone arrives at the same instants; with it, the arrivals spread across the window."}
```

## What the numbers cost

Full jitter makes some waits very short: phone 1's second wait is 5 milliseconds. That is fine. The
average wait is still half the ceiling, the ceiling still doubles, and a short wait now and then is
exactly what spreads the load. **The cap matters as much as the doubling.** Without it, the eighth
attempt would wait 128 seconds and the twelfth more than half an hour; with a cap of 60 seconds a
phone that has been offline all afternoon tries again within a minute of the network coming back.

And the waits are not timers in a phone that is asleep. A drain that is waiting forty seconds when
the system suspends the app does not wake up when the forty seconds are over; it runs again when the
app does, or when a background job is allowed to. Lesson 16 is what the systems allow.
