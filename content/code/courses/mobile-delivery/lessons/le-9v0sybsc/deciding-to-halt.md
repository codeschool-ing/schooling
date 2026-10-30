---
title: Deciding to halt, before anybody has to decide
version: 1
---

**The decision to halt a rollout should be a rule written before the release, not a judgement made
at eleven at night.** The rule compares the new version with the old one, on the same day, among
people of the same kind, and it refuses to say anything until enough people have used the new
version for the comparison to mean something.

## The planner's 1.5.0, simulated

Twenty thousand installs of the planner. Version 1.5.0 has a bug: on older Android phones, about
8% of installs, a quarter of launches crash. The rollout follows Apple's seven steps. Each day,
every install whose **bucket** is below the day's percentage gets 1.5.0, and the rule compares the
**crash-free users** of the two versions: the share of people who did not see a single crash that
day.

Save this as `rollout.ts`:

```schooling-example
{"language": "typescript", "file": "rollout.ts", "parts": [{"code": "// rollout.ts: a staged rollout simulated day by day, and the rule that halts it\nconst STAGES = [1, 2, 5, 10, 20, 50, 100];\nconst INSTALLS = 20_000;\nconst MIN_USERS = 500;\nconst MAX_DROP = 0.5;", "note": "Apple's seven daily steps, twenty thousand installs, and the rule's two numbers: say nothing below 500 people, halt on a drop of more than half a point."}, {"code": "function hash(text: string): number {\n  let h = 0x811c9dc5;\n  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 0x01000193) >>> 0;\n  return h;\n}\nconst installs = Array.from({ length: INSTALLS }, (_, i) => `install-${i}`);\nconst bucket = (id: string) => hash(`rollout:${id}`) % 10_000;", "note": "FNV-1a, a small hash that gives the same number for the same text on every run. Each install falls in one of 10,000 buckets, forever."}, {"code": "const crashes = (id: string, version: \"1.4.0\" | \"1.5.0\") => {\n  const roll = hash(`crash:${version}:${id}`) % 1000;\n  const oldAndroid = hash(`os:${id}`) % 100 < 8;\n  return version === \"1.5.0\" && oldAndroid ? roll < 250 : roll < 5;\n};\nfunction crashFree(ids: string[], version: \"1.4.0\" | \"1.5.0\"): number {\n  return (100 * ids.filter((id) => !crashes(id, version)).length) / ids.length;\n}", "note": "The invented bug: half a per cent of people crash on any version, and on 1.5.0 a quarter of the 8% with older Android do. Crash-free users is the share that saw no crash."}, {"code": "console.log(\"day  stage  on 1.5.0  crash-free 1.5.0  crash-free 1.4.0  decision\");\nfor (const [day, stage] of STAGES.entries()) {\n  const onNew = installs.filter((id) => bucket(id) < stage * 100);\n  const onOld = installs.filter((id) => bucket(id) >= stage * 100);\n  const fresh = crashFree(onNew, \"1.5.0\");\n  const old = onOld.length ? crashFree(onOld, \"1.4.0\") : NaN;", "note": "Each day, the installs below the day's percentage are on 1.5.0, and the rest are still on 1.4.0."}, {"code": "  let decision = \"continue\";\n  if (onNew.length < MIN_USERS) decision = `wait: fewer than ${MIN_USERS} users`;\n  else if (old - fresh > MAX_DROP) decision = \"HALT\";\n  console.log(`${String(day + 1).padStart(3)}  ${String(stage).padStart(4)}%  ${String(onNew.length).padStart(8)}  ${fresh.toFixed(2).padStart(15)}%  ${old.toFixed(2).padStart(15)}%  ${decision}`);\n  if (decision === \"HALT\") {\n    console.log(`halted on day ${day + 1}: ${onNew.length} installs keep 1.5.0 until a fix reaches them`);\n    break;\n  }\n}", "note": "The rule, in the order a person would apply it: first is there enough to judge, then is the new version worse."}]}
```

```
ana@dev:~/planner$ node rollout.ts
day  stage  on 1.5.0  crash-free 1.5.0  crash-free 1.4.0  decision
  1     1%       195            97.95%            99.46%  wait: fewer than 500 users
  2     2%       390            98.21%            99.46%  wait: fewer than 500 users
  3     5%      1011            96.24%            99.46%  HALT
halted on day 3: 1011 installs keep 1.5.0 until a fix reaches them
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-halt\" aria-label=\"A chart of crash-free users by day of the rollout, from 95% to 100%. Version 1.4.0 stays at 99.46% on days 1 to 3. Version 1.5.0 is 97.95% on day 1 and 98.21% on day 2, both in a shaded zone marked too few users to judge, and 96.24% on day 3, where the rule halts the rollout. Days 4 to 7 are never reached.\"><rect x=\"65.0\" y=\"30\" width=\"148.33333333333331\" height=\"220\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"139.16666666666666\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">too few users to judge</text><rect x=\"365.0\" y=\"30\" width=\"335.0\" height=\"220\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"532.5\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">never reached</text><path d=\"M60 250.0 L690 250.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">95%</text><path d=\"M60 206.0 L690 206.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">96%</text><path d=\"M60 162.0 L690 162.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">97%</text><path d=\"M60 118.0 L690 118.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">98%</text><path d=\"M60 74.0 L690 74.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">99%</text><path d=\"M60 30.0 L690 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"90.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"188.33333333333331\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"286.66666666666663\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"385.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"483.3333333333333\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"581.6666666666667\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"385.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day</text><text x=\"20\" y=\"12\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">crash-free users</text><path d=\"M90.0 53.760000000000275 L188.33333333333331 53.760000000000275 L286.66666666666663 53.760000000000275\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 120.19999999999987 L188.33333333333331 108.76000000000028 L286.66666666666663 195.44000000000023\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"298.66666666666663\" y=\"53.760000000000275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">1.4.0  99.46%</text><text x=\"100.0\" y=\"134.19999999999987\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">97.95%</text><text x=\"188.33333333333331\" y=\"96.76000000000028\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">98.21%</text><text x=\"298.66666666666663\" y=\"195.44000000000023\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">1.5.0  96.24%</text><text x=\"286.66666666666663\" y=\"217.44000000000023\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">halt</text></svg>", "caption": "Days 1 and 2 already look worse, and the rule still waits: with a few hundred people, a handful of crashes moves the rate by a point. Day 3 has a thousand, and the gap is three points."}
```

## Three things the simulation does that a real rule needs

**The bucket is a stable hash of the install, not a coin flipped each day.** The same people stay in
the rollout as it grows, so day 3's group contains day 2's, and nobody is moved back and forth
between versions. Google picks its users the same way; the lesson's hash only makes it visible.

**It waits for a sample.** On day 1, 1.5.0 looked worse than 1.4.0, with 195 people. On day 2 it
looked slightly better than on day 1, with 390. Neither number was enough to act on: with a few
hundred people, a handful of crashes moves the rate by a point. The rule says nothing below 500,
and that is a decision written down, not a feeling.

**It compares against the old version on the same day.** A crash-free rate of 96% means nothing on
its own. Next to 99.46% for the version everybody else has, on the same day and the same kind of
phones, it is the 3-point drop that stops the release.

## Where the numbers come from in reality

The simulation invents the crashes. A real rollout reads them from the crash reporter of lesson 12,
which groups them by version, and from each store's console: **Android vitals** in the Play Console
shows the crash rate per release, and App Store Connect shows crashes per version from devices
that share analytics. Lesson 12 is where those numbers start.
