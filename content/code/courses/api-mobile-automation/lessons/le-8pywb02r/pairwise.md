---
title: Pairwise, or every pair instead of every combination
version: 1
---

**Pairwise testing picks combinations so that every value of every dimension meets every value of
every other dimension at least once.** It rests on an observation about real defects: most are
triggered by one setting on its own, such as a small screen, or by two together, such as a small
screen in Portuguese, and far fewer need three or more particular values at once. Studies of failure
reports by NIST, among others, found that pattern across many kinds of software. Testing every pair
catches the first two kinds with a fraction of the rows.

The wrong belief is that fewer combinations means less coverage in proportion: 12 rows out of 72
cannot test a sixth of what 72 do. They test every pair of values together, which is all of what
most defects need. **What they give up is named**: a defect that appears only with Android 12 on a
tablet from Xiaomi in English, three particular values at once, is caught only if that row happens
to be chosen.

## A pairwise set, built by a script

The matrix of section 02: four Android versions, the three that cover 90% of section 03's sessions
plus 12, the oldest one still worth a row; three screen classes; the three makers that cover 96.4%;
and two languages. The script builds the full product, lists every pair of values that has to meet,
and then, greedily, keeps taking the combination that covers the most pairs not yet covered, until
none is left. Save it as `matrix/pairwise.mjs`:

```js
// matrix/pairwise.mjs: a pairwise set for a compatibility matrix, built greedily
const factors = {
  android: ['12', '13', '14', '15'],
  screen: ['small phone', 'large phone', 'tablet'],
  maker: ['Samsung', 'Motorola', 'Xiaomi'],
  language: ['pt-BR', 'en'],
};
const names = Object.keys(factors);

// every combination of one value per factor: the full product
let all = [[]];
for (const name of names) {
  all = all.flatMap((row) => factors[name].map((value) => [...row, value]));
}

// the pairs one row covers: a value of one factor beside a value of another
const pairsOf = (row) => {
  const out = [];
  for (let i = 0; i < row.length; i++) {
    for (let j = i + 1; j < row.length; j++) out.push(`${i}=${row[i]}|${j}=${row[j]}`);
  }
  return out;
};
const uncovered = new Set(all.flatMap(pairsOf));
const total = uncovered.size;

// greedy: take the row that covers the most pairs not yet covered, until none is left
const chosen = [];
while (uncovered.size > 0) {
  let best = null;
  let gain = 0;
  for (const row of all) {
    const g = pairsOf(row).filter((p) => uncovered.has(p)).length;
    if (g > gain) [best, gain] = [row, g];
  }
  chosen.push(best);
  for (const p of pairsOf(best)) uncovered.delete(p);
}

console.log(names.map((n) => n.padEnd(13)).join('').trimEnd());
for (const row of chosen) console.log(row.map((v) => v.padEnd(13)).join('').trimEnd());
console.log(`${chosen.length} rows cover all ${total} pairs; the full product has ${all.length} rows`);
```

```
ana@laptop:~/boxoffice$ node matrix/pairwise.mjs
android      screen       maker        language
12           small phone  Samsung      pt-BR
12           large phone  Motorola     en
13           small phone  Xiaomi       en
13           tablet       Motorola     pt-BR
14           large phone  Xiaomi       pt-BR
14           tablet       Samsung      en
15           small phone  Motorola     pt-BR
15           large phone  Samsung      en
12           tablet       Xiaomi       pt-BR
13           large phone  Samsung      pt-BR
14           small phone  Motorola     pt-BR
15           tablet       Xiaomi       pt-BR
12 rows cover all 53 pairs; the full product has 72 rows
```

**12 rows cover all 53 pairs that the 72 rows contain.** Read any two columns and every pairing
appears somewhere: Android 12 with a tablet in row 9, Xiaomi with English in row 3, a small phone in
Portuguese in rows 1, 7 and 11. Twelve is also the least any set could manage here, because Android's
four versions and the three screens alone make twelve pairs and each row holds only one of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 342\" role=\"img\" aria-label=\"A grid of all 72 combinations: four Android versions times three screen classes down the side, three makers times two languages across the top. Twelve cells are filled and numbered 1 to 12 in the order the pairwise script printed them; every row of three screens for one Android version, and every maker and language column, contains at least one filled cell, and every pair of values shares a filled cell somewhere.\"><text x=\"284\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Samsung</text><text x=\"249\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"319\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"424\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Motorola</text><text x=\"389\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"459\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"564\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Xiaomi</text><text x=\"529\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"599\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"56\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 12</text><text x=\"204\" y=\"83.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">small phone</text><rect x=\"216\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"83.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1</text><rect x=\"286\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">large phone</text><rect x=\"216\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"459\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2</text><rect x=\"496\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"529\" y=\"121.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">9</text><rect x=\"566\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 13</text><text x=\"204\" y=\"140.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">small phone</text><rect x=\"216\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"599\" y=\"140.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">3</text><text x=\"204\" y=\"159.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">large phone</text><rect x=\"216\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">10</text><rect x=\"286\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"178.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">4</text><rect x=\"426\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 14</text><text x=\"204\" y=\"197.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">small phone</text><rect x=\"216\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11</text><rect x=\"426\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"216.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">large phone</text><rect x=\"216\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"529\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">5</text><rect x=\"566\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"235.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"319\" y=\"235.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">6</text><rect x=\"356\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"273.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 15</text><text x=\"204\" y=\"254.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">small phone</text><rect x=\"216\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"254.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">7</text><rect x=\"426\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"273.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">large phone</text><rect x=\"216\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"319\" y=\"273.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">8</text><rect x=\"356\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"292.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"529\" y=\"292.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12</text><rect x=\"566\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12 of the 72 combinations, numbered as the script printed them; every pair of values meets in at least one</text></svg>", "caption": "The full product has 72 cells; the pairwise set fills 12 of them and still puts every pair of values together at least once."}
```

## What a tool does that this script does not

A greedy script like this one is enough to see the idea and to build a small matrix. Real tools,
Microsoft's PICT among them, add what a real matrix needs:

- **constraints**: some combinations do not exist, a Motorola tablet on Android 15 may not be
  sold, and the set must be built around them rather than containing a row nobody can run;
- **a stronger strength where it is wanted**: every three values together for the two or three
  dimensions you fear most, pairs for the rest;
- **seeding**: rows you must have, such as your best-selling phone on its current version, kept in
  and built around.

Whatever builds it, **a pairwise set is a list of configurations, not of tests**. Each row is a
device to run the same suite on, the Appium or Espresso tests of lessons 15 and 16, which section
06 points at a cloud.
