---
title: A screen that says what it knows
version: 1
---

**A screen that depends on the network is in one of four states, and it should never be unclear
which.** It is loading, or it shows what the server just said, or it shows an older copy because
the server could not be reached, or it has nothing to show. The common mistake is to draw only the
first two: a spinner, and then the data. Then the lift arrives, and the student gets a spinner that
never stops, or an empty week that looks exactly like a week with nothing planned.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l14-states\" aria-label=\"The four states of a screen that loads from the network. Loading leads to fresh when the server answers. When it does not, the screen looks for a saved copy: with one, it shows the stale state, the saved data and its age; without one, it shows the error state, what went wrong and a Try again button. Try again, from stale or from error, goes back to loading.\"><defs><marker id=\"l14-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">loading</text><text x=\"95.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">asking, with a deadline</text><rect x=\"270\" y=\"20\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"38.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fresh</text><text x=\"355.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the week, as sent</text><rect x=\"290\" y=\"170\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"355.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a saved</text><text x=\"355.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy?</text><rect x=\"520\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stale</text><text x=\"615.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the saved week, and its age</text><rect x=\"520\" y=\"190\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"208.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">error</text><text x=\"615.0\" y=\"221.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">what went wrong, and Try again</text><path d=\"M170 112 L270 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-phosphor)\"></path><text x=\"200\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">answered</text><path d=\"M170 138 L290 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-amber)\"></path><text x=\"200\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">failed or timed out</text><path d=\"M420 186 L520 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"466\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">yes</text><path d=\"M420 206 L520 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"470\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no</text><path d=\"M615 110 L615 90 L95 90 L95 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Try again</text><path d=\"M710 215 L714 215 L714 250 L12 250 L12 125 L20 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path></svg>", "caption": "Four states, and each says something different. Stale with its age, and an error with a way out, are the two most apps forget."}
```

Each state has one thing it must say:

| state | what the screen shows | what it must not do |
|---|---|---|
| loading | that it is asking | spin for ever: the deadline ends it |
| fresh | the week, as the server sent it | anything else |
| stale | the saved week, **and how old it is** | pass the old copy off as current |
| error | what went wrong, in the user's words, and a way to try again | show an empty week, or a stack trace |

**The stale state is the one that makes an app usable in a lift.** The planner's week changes a few
times a day at most, so a copy from two hours ago is nearly always right, and far more useful than
nothing. What makes it honest is the age beside it: the student can decide for themselves whether
the copy is good enough. An app that shows the old copy without saying so has replaced "I could not
check" with a claim that it did.

## The week screen, without a screen

`screen.ts` does what the planner's week screen does with the network, and prints the screen's text
instead of drawing it. It asks the server with a five-second deadline; when that works, it saves the
answer in `week.json` with the time it was fetched. When it fails, it reads the saved copy and says
how old it is. "Now" is given as an argument, like "today" in lesson 1's `week.ts`, so that the ages
below come out the same on your computer. Save it as `screen.ts`:

```typescript
// screen.ts: what the week screen says, from the server or from the copy it kept
import { readFileSync, writeFileSync } from "node:fs";
import { fetchWeek } from "./fetchweek.ts";

type Week = { monday: string; planned: number; done: number };
type Saved = { fetchedAt: string; week: Week };

const now = new Date(process.argv[2]); // given, like "today" in week.ts
const show = (w: Week) => `week of ${w.monday}: ${w.done} of ${w.planned} minutes done`;

function ago(then: string): string {
  const min = Math.round((now.getTime() - new Date(then).getTime()) / 60000);
  return min < 60 ? `${min} min` : `${Math.floor(min / 60)} h ${min % 60} min`;
}

function saved(): Saved | undefined {
  try {
    return JSON.parse(readFileSync("week.json", "utf8"));
  } catch {
    return undefined; // no copy, or one that cannot be read: either way nothing to show
  }
}

console.log("Loading the week…");
try {
  const week: Week = await fetchWeek("http://127.0.0.1:8014/week", { timeoutMs: 5000 });
  writeFileSync("week.json", JSON.stringify({ fetchedAt: now.toISOString(), week }));
  console.log(show(week));
} catch {
  const copy = saved();
  if (copy) {
    console.log(`${show(copy.week)} (saved ${ago(copy.fetchedAt)} ago, could not refresh)`);
  } else {
    console.log("Could not reach the planner, and there is no saved copy yet.");
  }
  console.log("[Try again]");
}
```

**Run it three times: with the server up, with it stopped, and with the saved copy gone.** The
first run is at 8:30 in the morning in São Paulo. Then stop the server with Ctrl+C in its terminal,
and run it again at 10:45:

```
ana@dev:~/planner$ node screen.ts 2026-10-21T08:30:00-03:00
Loading the week…
week of 2026-10-19: 120 of 180 minutes done
ana@dev:~/planner$ cat week.json
{"fetchedAt":"2026-10-21T11:30:00.000Z","week":{"monday":"2026-10-19","planned":180,"done":120}}
ana@dev:~/planner$ node screen.ts 2026-10-21T10:45:00-03:00
Loading the week…
week of 2026-10-19: 120 of 180 minutes done (saved 2 h 15 min ago, could not refresh)
[Try again]
ana@dev:~/planner$ rm week.json
ana@dev:~/planner$ node screen.ts 2026-10-21T10:46:00-03:00
Loading the week…
Could not reach the planner, and there is no saved copy yet.
[Try again]
```

The first run reached the server and saved its answer; `week.json` holds the time in UTC, which is
three hours ahead of São Paulo, and the week as it came. The second run met a connection that was
refused, because nothing listens on port 8014 any more, and showed the saved week with its age:
**2 h 15 min**, from 8:30 to 10:45. The third run had no copy to fall back on, and said so, with the
one thing the student can do about it.

## What this leaves out on purpose

**The copy here is a small JSON file in the working folder**, which is enough to show the states.
On a phone it lives in the app's own storage, and lesson 16 is about where that is and what the
system may delete. The error is also deliberately vague to the student: "could not reach the
planner" is what they can act on, and the `ECONNREFUSED` behind it belongs in a log for the
developer, not on the screen.

**The screen also refreshes on its own**, in a real app, when the network comes back, which is the
connectivity callback doing the one job it is good at. The `mobile-offline` course takes the idea
much further in its lesson 7, where the app writes to its own copy first and the server learns
about it afterwards.
