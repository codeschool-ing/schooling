---
title: Cohorts, and the curve that flattens
version: 1
---

**Retention is the share of people who come back, measured for a group of people who started at the
same time.** That group is a **cohort**: everybody who installed in the week of 7 September is one,
the week of 14 September another. Following each cohort separately is what makes retention honest.
A total of active users mixes this week's new installs with last year's loyal ones, and can rise
while every cohort is leaving faster than the one before it.

## Four cohorts, in SQLite

The data is a list of days on which each installation opened the app, the `app_open` events of
lesson 16 reduced to one row per installation per day. To have eight weeks of it here, a short
program makes four weekly cohorts of 300 installs, starting on the four Mondays of September 2026,
with two kinds of people in them: a quarter who make the planner a habit, and the rest, who try it
and drift away. A seeded generator makes the same data on every run. Save this as `retention.ts` in
`~/planner`:

```typescript
// retention.ts: four weekly cohorts of installs, the weeks they came back, and the ratios people quote
import Database from "better-sqlite3";

let seed = 17;
const random = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
const day = (start: string, plus: number) => {
  const d = new Date(`${start}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + plus);
  return d.toISOString().slice(0, 10);
};

const db = new Database(":memory:");
db.exec("create table opens (install text, cohort text, day text)");
const insert = db.prepare("insert into opens values (?, ?, ?)");
const cohorts = ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28"];
for (const cohort of cohorts) {
  for (let i = 0; i < 300; i++) {
    const install = `${cohort}/${i}`;
    const keen = random() < 0.25;
    for (let d = 0; d < 56 && day(cohort, d) <= "2026-10-31"; d++) {
      const week = Math.floor(d / 7);
      const chance = d === 0 ? 1 : (keen ? 0.3 : 0.08) * Math.pow(keen ? 0.92 : 0.35, week);
      if (random() < chance) insert.run(install, cohort, day(cohort, d));
    }
  }
}

console.log("cohort      installs  week 0  week 1  week 2  week 3  week 4");
for (const cohort of cohorts) {
  const cells = [0, 1, 2, 3, 4].map((w) => {
    if (day(cohort, w * 7 + 6) > "2026-10-31") return "".padStart(6);
    const { n } = db.prepare("select count(distinct install) as n from opens where cohort = ? and day >= ? and day < ?")
      .get(cohort, day(cohort, w * 7), day(cohort, w * 7 + 7)) as { n: number };
    return `${Math.round((100 * n) / 300)}%`.padStart(6);
  });
  console.log(`${cohort}  ${"300".padStart(8)}  ${cells.join("  ")}`.trimEnd());
}

const on = "2026-10-26";
const active = (from: string) =>
  (db.prepare("select count(distinct install) as n from opens where day >= ? and day <= ?").get(from, on) as { n: number }).n;
const dau = active(on), wau = active(day(on, -6)), mau = active(day(on, -29));
console.log(`on ${on}: DAU ${dau}, WAU ${wau}, MAU ${mau}, DAU/MAU ${Math.round((100 * dau) / mau)}%, WAU/MAU ${Math.round((100 * wau) / mau)}%`);
```

```
ana@dev:~/planner$ node retention.ts
cohort      installs  week 0  week 1  week 2  week 3  week 4
2026-09-07       300    100%     36%     25%     23%     22%
2026-09-14       300    100%     41%     30%     25%     25%
2026-09-21       300    100%     37%     26%     20%     19%
2026-09-28       300    100%     38%     24%     22%
on 2026-10-26: DAU 59, WAU 247, MAU 652, DAU/MAU 9%, WAU/MAU 38%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-curves\" aria-label=\"Four retention curves, one per weekly cohort of September 2026. All four start at 100% in week 0, fall to between 36% and 41% in week 1, and then flatten: between 24% and 30% in week 2, 20% to 25% in week 3, and 19% to 25% in week 4, where the last cohort has no data yet.\"><path d=\"M84 230.0 L530 230.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><path d=\"M84 180.0 L530 180.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25%</text><path d=\"M84 130.0 L530 130.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M84 80.0 L530 80.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75%</text><path d=\"M84 30.0 L530 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"90.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"197.5\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"305.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"412.5\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"520.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"305.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week</text><text x=\"20\" y=\"12\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">share of the cohort that opened the app</text><path d=\"M90.0 30.0 L197.5 158.0 L305.0 180.0 L412.5 184.0 L520.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 148.0 L305.0 170.0 L412.5 180.0 L520.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 156.0 L305.0 178.0 L412.5 190.0 L520.0 192.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 154.0 L305.0 182.0 L412.5 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M560 180 L590 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">2026-09-07</text><path d=\"M560 198 L590 198\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">2026-09-14</text><path d=\"M560 216 L590 216\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-09-21</text><path d=\"M560 234 L590 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-09-28</text><text x=\"560\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">the first week loses six in ten</text><text x=\"560\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">then the curve flattens</text></svg>", "caption": "The four cohorts drawn from the table. The steep part is week 1 and the flat part is the people the app is for; every curve has the same shape."}
```

## Reading the table

**Every cohort loses about six in ten people in its first week.** That is normal for mobile apps, and
it is the most important number in the table: week 1 is where the planner either becomes part of
somebody's week or does not. **Then the curve flattens.** From week 2 the cohorts lose a few points a
week, and by week 4 about a fifth of each is still there. Those are the people the product is
actually for, and the flat part of the curve is what a business is built on.

The last cohort has no week 4, because its fifth week ends after 31 October, where the data does. A
week that has not finished would report fewer people than it will, and look like a fall that has not
happened.

## What a retention number needs beside it

- **The definition of "came back"**: here, opened the app at least once in the week. "Finished a
  session", lesson 16's last step, is stricter and lower, and often the better one.
- **The cohort's size**: 300 people make a percentage move by a third of a point each; 30 people make
  it jump by three.
- **The comparison**: retention is read across cohorts, older against newer, to see whether a release
  or a change of onboarding moved week 1.
