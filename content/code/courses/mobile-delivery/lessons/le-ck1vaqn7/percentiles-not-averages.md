---
title: Percentiles, not averages
version: 1
---

**The average start-up time is the number that hides the people who are suffering.** Start-up
times are not spread evenly around a middle: most are short, and a long tail is very long, on old
phones, on full storage, on a busy day. An average pulls the tail into the middle and reports a
number nobody experienced. **Percentiles** report what people did experience: the 50th percentile,
p50, is the time half the starts were faster than; p90 is the time nine starts in ten beat; p99 is the
one-in-a-hundred.

## A week of field data

Real numbers come from Android vitals, Xcode's Organizer or your own measurements sent the way
lesson 16 sends events. To have a week of them here, a short program makes 5000 cold starts across
three kinds of phone, each with a typical time and a spread around it, from a seeded random number
generator, so every run makes the same week. Save this as `field.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "field.ts", "parts": [{"code": "// field.ts: a week of cold starts from the field, and why the average says the wrong thing\nfunction mulberry32(seed: number) {\n  return () => {\n    seed = (seed + 0x6d2b79f5) | 0;\n    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);\n    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;\n    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;\n  };\n}\nconst random = mulberry32(2026);\nconst normal = () => Math.sqrt(-2 * Math.log(1 - random())) * Math.cos(2 * Math.PI * random());", "note": "A small seeded random number generator, so the same week comes out on every run, and a normal distribution made from it."}, {"code": "const tiers = [\n  { name: \"high-end\", share: 0.3, median: 650 },\n  { name: \"mid-range\", share: 0.5, median: 1100 },\n  { name: \"low-end\", share: 0.2, median: 2400 },\n];\nconst starts: { tier: string; ms: number }[] = [];\nfor (let i = 0; i < 5000; i++) {\n  const r = random();\n  const tier = r < 0.3 ? tiers[0] : r < 0.8 ? tiers[1] : tiers[2];\n  starts.push({ tier: tier.name, ms: Math.round(tier.median * Math.exp(0.35 * normal())) });\n}", "note": "Three kinds of phone in the shares a real audience has, each with a typical cold start. Multiplying by `exp` of a normal gives the long tail real start-up times have."}, {"code": "function pct(values: number[], p: number): number {\n  const sorted = [...values].sort((a, b) => a - b);\n  return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];\n}", "note": "A percentile: sort, and read the value that the given share of starts is below."}, {"code": "function row(label: string, values: number[]) {\n  const mean = Math.round(values.reduce((n, v) => n + v, 0) / values.length);\n  console.log(`${label.padEnd(10)} ${String(values.length).padStart(5)}  ${String(mean).padStart(5)}  ${[50, 90, 99].map((p) => String(pct(values, p)).padStart(5)).join(\"  \")}`);\n}\nconsole.log(`${\"cold start\".padEnd(10)} ${\"n\".padStart(5)}  ${\"mean\".padStart(5)}  ${[\"p50\", \"p90\", \"p99\"].map((h) => h.padStart(5)).join(\"  \")}`);\nrow(\"all\", starts.map((s) => s.ms));\nfor (const t of tiers) row(t.name, starts.filter((s) => s.tier === t.name).map((s) => s.ms));", "note": "One row for everybody, then one per kind of phone, each with its count, mean and three percentiles, in milliseconds."}]}
```

```
ana@dev:~/planner$ node field.ts
cold start     n   mean    p50    p90    p99
all         5000   1313   1055   2489   4346
high-end    1562    697    655   1008   1444
mid-range   2417   1177   1116   1730   2524
low-end     1021   2578   2425   3824   5345
```

## Reading the table

**The mean says 1.3 seconds and the p50 says 1.1, and both describe a fast app.** The p90 says one
start in ten takes 2.5 seconds or more. Split by kind of phone, the low-end row says something the
first row cannot: half of those people wait 2.4 seconds or more, one in ten waits 3.8, and one in a
hundred waits more than 5.

Three habits follow:

- **Watch p90 and p99 beside p50**, never the mean on its own. A release that improves the mean and
  worsens p99 made the app slower for the people most likely to leave.
- **Split by kind of phone**, and by system version. The planner's users are mostly mid-range in this
  data, and the low-end fifth is where the long tail lives.
- **Compare against the previous release, on the same days.** A p90 of 2.5 seconds is neither good
  nor bad on its own; 2.5 after 2.1 is a regression with a cause in the diff.

## Why the slow tenth decides

People on the slowest phones are not a rounding error. They are the people whose phones have the
least space, lesson 18, and the least patience left for an app that keeps them waiting; and their
one-star reviews are read by people with fast phones deciding whether to install. **A percentile is
a promise about a share of real people**, and p90 is a promise to nine in ten of them.
