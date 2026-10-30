---
title: A release that rolls out, and what cannot be taken back
version: 1
---

**Publishing is not one moment; a new version reaches its users over days, and some of them never get
it.** The common picture is that pressing release updates everybody. On a phone, an update arrives
when the store hands it out and the phone installs it, and both stores let you hand it out slowly on
purpose, so that a bad version reaches a few people before it reaches all of them.

## Apple's phased release

**Apple's version is a fixed seven-day schedule for automatic updates.** App Store Connect's help page
on releasing an update in phases, read on 30 October 2026, says the option "will release your app's
update gradually over 7 days" to "a random sample of users with automatic updates on eligible
devices", and gives the schedule as a table:

| day | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| percentage of users | 1% | 2% | 5% | 10% | 20% | 50% | 100% |

Three details on the same page change how to read it. **Anyone can still download the new version by
hand**, from the App Store, at any time: the phases only govern automatic updates. **The release can be
paused** for a total of 30 days, "with no limit on the number of pauses", and when it resumes it
"will pick up on the day it was left off". And it can be released to all users at any moment, which
is the button a team presses when the first days look clean.

**Google Play's version is a staged rollout, where the team chooses the percentage.** A production
release goes to a fraction of users the team sets, the fraction is raised as confidence grows, and the
rollout can be halted. Google's own description is on its Play Console Help pages, which could not be
reached when this was written, so this lesson gives no schedule for Play: there is no fixed one to
quote, and the percentages are the team's.

## The schedule, as a program

The program below lays Apple's schedule over the calendar, starting on Monday 2 November 2026, with a
pause: a crash report arrives on day 3, and the team pauses for two days while it looks. Save it as
`rollout.ts` in `~/planner`:

```typescript
// rollout.ts: a phased release, day by day, with a pause in the middle
const APPLE = [1, 2, 5, 10, 20, 50, 100]; // percent of automatic updates on day 1 to 7

// Each calendar day from `start`: the phase day reached and its percentage. A paused day
// does not advance the phase, and the release resumes on the day it left off.
export function schedule(start: string, phases: number[], paused: string[]) {
  if (paused.length > 30) throw new Error("a phased release may be paused for 30 days in all");
  const rows: string[] = [];
  const d = new Date(start + "T12:00:00Z");
  let phase = 0;
  while (phase < phases.length) {
    const day = d.toISOString().slice(0, 10);
    if (paused.includes(day)) {
      rows.push(`${day}  paused   still ${phases[phase - 1] ?? 0}%`);
    } else {
      rows.push(`${day}  day ${phase + 1}    ${phases[phase]}%`);
      phase++;
    }
    d.setUTCDate(d.getUTCDate() + 1);
  }
  return rows;
}

// A crash report arrives on day 3; the release is paused for two days, then resumed.
for (const row of schedule("2026-11-02", APPLE, ["2026-11-05", "2026-11-06"])) console.log(row);
```

```
ana@dev:~/planner$ node rollout.ts
2026-11-02  day 1    1%
2026-11-03  day 2    2%
2026-11-04  day 3    5%
2026-11-05  paused   still 5%
2026-11-06  paused   still 5%
2026-11-07  day 4    10%
2026-11-08  day 5    20%
2026-11-09  day 6    50%
2026-11-10  day 7    100%
```

**The pause holds the percentage where it was.** For two days nobody new gets the update, and the 5%
who already have it keep it: pausing stops the spreading, not the version. On 7 November the
schedule resumes at day 4, 10%, not at day 6, and the release reaches everybody on the tenth instead of
the eighth. If the crash had been real, the next step would have been a new build with a higher
build number, through review again, which is the whole of `mobile-delivery` lesson 8.

## What cannot be taken back

**A version that reached a phone stays on that phone until its user updates it, and some never do.**
Neither store can uninstall your old version from a user's phone. A user with automatic updates off,
or a phone too old for the new version's minimum system, keeps the old build indefinitely. Three
consequences follow, and the planner has to live with all of them:

- **The build number is spent.** A version code or build number that went out cannot be reused, as
  the previous section showed, and the next release must be higher.
- **Old clients keep calling your server.** If the planner syncs, the server has to answer the
  version from last year as well as this week's, which is `mobile-delivery` lesson 20, "the app that
  never updates".
- **A bad release is fixed forwards.** There is no rolling a phone back to the previous build; the
  remedy is a newer build, which is exactly why the phased release exists, to make the number of
  phones holding a bad one small.

## The app you published keeps living

**A published app is also subject to rules that change after it shipped.** Android's documentation
on Google Play's target API level requirement, read on 30 October 2026, says that starting **31
August 2026**, "new apps and app updates must target Android 16 (API level 36) or higher" to be
submitted, with exceptions for Wear OS, Android Automotive OS, Android TV and Android XR. Existing apps must target Android 15 (API level 35) or higher "to remain available to new users" on
newer devices. Developers who need more time can ask for an extension to **1 November 2026**. So an
app nobody touched for a year can stop being offered to new users on new phones without anybody
having changed a line of it.

**The systems move too.** A new Android or iOS release changes a permission, a background limit or a
layout rule, the subjects of lessons 12, 15 and 9, and an app built against last year's system meets this
year's on the first day of the update. A planner that is published is a planner that someone on the
team reads release notes for, every year, for as long as it is on sale.
