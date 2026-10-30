---
title: The app that never updates
version: 1
---

**A website is replaced on every visit; an installed app stays the version it was until its owner
updates it.** Automatic updates on both stores close most of the gap, and not all of it: a phone
with automatic updates switched off, one that only updates on Wi-Fi and is rarely on Wi-Fi, one too
old for the newest version's minimum OS, a tablet in a drawer that comes out once a term. Each of
them still opens the planner, still calls the API, and expects it to answer the way it did on the day
that version shipped.

So the first question of this lesson is not technical. **Which versions are still out there, and how
many people use each?**

## Counting them

The app sends its version with every request, the way the planner's client in lesson 19 did, and the
server counts distinct installations per version over a window. The window matters: 28 days counts
people who use the app, while "every install ever" counts phones in drawers.

The numbers below are an example, shaped like a real app a year after its first release:
installations that opened the planner in the last 28 days, by the version they ran. Save them in
`~/planner` as `seen.json`:

```json
{
  "1.6.0": 3120,
  "1.5.2": 1480,
  "1.5.1": 260,
  "1.5.0": 95,
  "1.4.3": 610,
  "1.4.0": 140,
  "1.3.1": 230,
  "1.2.0": 88,
  "1.1.0": 41,
  "1.0.0": 17
}
```

Save this as `support.ts`. It prints the share of each version, the share at that version or newer,
and, for the minimum given on the command line, how many people would meet the update screen:

```typescript
// support.ts: share per version, newest first, and who a minimum version would stop
import { readFileSync } from "node:fs";

const seen: Record<string, number> = JSON.parse(readFileSync("seen.json", "utf8"));
const parts = (v: string) => v.split(".").map(Number);
const newer = (a: string, b: string) => {
  const [x, y] = [parts(a), parts(b)];
  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] > y[i];
  return false;
};
const versions = Object.keys(seen).sort((a, b) => (newer(a, b) ? -1 : 1));
const total = versions.reduce((n, v) => n + seen[v], 0);
const pct = (n: number) => ((100 * n) / total).toFixed(1).padStart(5) + "%";

let atLeast = 0;
console.log("version  installs  share  this or newer");
for (const v of versions) {
  atLeast += seen[v];
  console.log(`${v.padEnd(7)}  ${String(seen[v]).padStart(8)}  ${pct(seen[v])}  ${pct(atLeast)}`);
}
const minimum = process.argv[2];
if (minimum) {
  const stopped = versions.filter((v) => newer(minimum, v)).reduce((n, v) => n + seen[v], 0);
  console.log(`minimum ${minimum}: ${stopped} of ${total} installs (${pct(stopped).trim()}) meet the update screen`);
}
```

Run it with the minimum the planner set in lesson 19, 1.5.1, then with a gentler one, 1.4.0, keeping
only the last line:

```
ana@dev:~/planner$ node support.ts 1.5.1
version  installs  share  this or newer
1.6.0        3120   51.3%   51.3%
1.5.2        1480   24.3%   75.6%
1.5.1         260    4.3%   79.9%
1.5.0          95    1.6%   81.5%
1.4.3         610   10.0%   91.5%
1.4.0         140    2.3%   93.8%
1.3.1         230    3.8%   97.6%
1.2.0          88    1.4%   99.0%
1.1.0          41    0.7%   99.7%
1.0.0          17    0.3%  100.0%
minimum 1.5.1: 1221 of 6081 installs (20.1%) meet the update screen
ana@dev:~/planner$ node support.ts 1.4.0 | tail -n 1
minimum 1.4.0: 376 of 6081 installs (6.2%) meet the update screen
```

**A year after its first release, 18.5% of the installations still run a version from before 1.5.**
The tail is long and thin: the three oldest versions together are 2.4%, and they will be there next
year too. The two `minimum` lines are the trade lesson 19 left open. A minimum of 1.5.1 stops 1221
installations, one in five, all of them people who did nothing wrong except not update. A minimum of
1.4.0 stops 376, about one in sixteen.

## What the count decides

- **The support window.** Write down which versions the API answers, as a rule rather than a
  feeling: "every version released in the last 12 months", or "the last three minor versions". The
  count is how you check the rule against the people it would cut off.
- **The minimum OS.** The same table by operating-system version, which both stores also report,
  tells you what raising the app's minimum OS costs. Dropping an OS version stops new installs and
  updates on those phones, and the copy already installed keeps running, with no further updates.
- **What testing covers.** A version with 4% of your users deserves a run of its contract test,
  section three, on every server deploy. A version nobody runs deserves to leave the window.

The table cannot tell you why a version is still there. A phone stuck on 1.2.0 may be stuck because
its OS cannot install 1.3; raising the minimum then sends that person to an update they cannot
install. **Check what the oldest versions run on before sending them to a screen with no way out.**
