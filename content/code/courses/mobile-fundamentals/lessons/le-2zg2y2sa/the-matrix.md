---
title: A scoring matrix, and the weight that flips it
version: 1
---

**A decision matrix turns the seven questions into arithmetic: a weight for how much each criterion
matters, a score for how well each approach serves it, and a total per approach.** The arithmetic
is trivial. The value is that it makes every judgement visible, so that a team argues about "is time
to market a 3 or a 5 for us?" instead of about which tool is better.

## The planner's matrix

Here is one for the planner, as the startup team of the previous section might fill it in: a team
that writes TypeScript, already has the planner as a web app, and wants both stores. **The scores are
judgements for that team, not facts about the tools**, and the first thing to do with this file is
to disagree with some of them. Save it in `~/planner` as `choose.ts`:

```schooling-example
{"language": "typescript", "file": "choose.ts", "parts": [{"code": "// choose.ts: criteria, approaches and weights, for one team's decision\ntype Approach = \"native\" | \"react-native\" | \"flutter\" | \"kmp\" | \"wrapper\";\ntype Row = Record<Approach, number>;\n\n// How much each criterion matters to this team: 0 (not at all) to 5.\nconst weights: Record<string, number> = {\n  languages: 4,\n  features: 2,\n  performance: 2,\n  time: 3,\n  platforms: 3,\n  cost: 3,\n  hiring: 2,\n};\n", "note": "The weights: the team's priorities, and the part of the file to argue about first. Zero means the criterion does not count at all."}, {"code": "// How well each approach serves each criterion, for this team: 1 to 5.\nconst scores: Record<string, Row> = {\n  languages:   { native: 1, \"react-native\": 5, flutter: 2, kmp: 1, wrapper: 5 },\n  features:    { native: 5, \"react-native\": 4, flutter: 4, kmp: 5, wrapper: 3 },\n  performance: { native: 5, \"react-native\": 4, flutter: 4, kmp: 5, wrapper: 2 },\n  time:        { native: 1, \"react-native\": 3, flutter: 3, kmp: 2, wrapper: 5 },\n  platforms:   { native: 2, \"react-native\": 5, flutter: 5, kmp: 4, wrapper: 5 },\n  cost:        { native: 2, \"react-native\": 4, flutter: 4, kmp: 3, wrapper: 3 },\n  hiring:      { native: 4, \"react-native\": 4, flutter: 3, kmp: 2, wrapper: 4 },\n};\n", "note": "The scores, one row per criterion. `languages` gives React Native and the wrapper 5 because this team writes TypeScript; `time` gives the wrapper 5 because the team's web app already has its screens. Another team fills in different numbers."}, {"code": "function fail(message: string): never {\n  console.error(message);\n  process.exit(1);\n}\n\n// node choose.ts time=5 changes one weight for this run.\nfor (const arg of process.argv.slice(2)) {\n  const [name, value] = arg.split(\"=\");\n  if (!(name in weights)) fail(`no criterion \"${name}\"; there are: ${Object.keys(weights).join(\", \")}`);\n  const w = Number(value);\n  if (!Number.isInteger(w) || w < 0 || w > 5) fail(`the weight of ${name} must be 0 to 5, not \"${value}\"`);\n  weights[name] = w;\n}\n", "note": "A weight can be changed from the command line, for one run, without editing the file. A name that is not a criterion, or a weight outside 0 to 5, stops the program instead of being ignored."}, {"code": "const approaches = Object.keys(scores.languages) as Approach[];\nconst ranked = approaches\n  .map((a) => ({ a, total: Object.keys(weights).reduce((sum, c) => sum + weights[c] * scores[c][a], 0) }))\n  .sort((x, y) => y.total - x.total);\n\nconsole.log(\"weights:\", Object.entries(weights).map(([c, w]) => `${c} ${w}`).join(\", \"));\nfor (const { a, total } of ranked) console.log(String(total).padStart(4), a);", "note": "Each approach's total is the sum of weight times score over the seven criteria, and the list is printed highest first, under the weights that produced it."}]}
```

Run it:

```
ana@dev:~/planner$ node choose.ts
weights: languages 4, features 2, performance 2, time 3, platforms 3, cost 3, hiring 2
  80 react-native
  77 wrapper
  66 flutter
  55 kmp
  47 native
```

**React Native first, the wrapper three points behind.** Read the totals back against the scores:
React Native scores 5 on languages, weighted 4, which is 20 of its 80; native scores 1 there, which
is 4, and loses most of its ground on that one line. The matrix has not said anything you could not
have argued. It has said it in a form where every step can be checked.

## Change one weight

Now suppose the investors move the date forward, and time to market stops being a 3 and becomes a
5. Nothing about the tools has changed:

```
ana@dev:~/planner$ node choose.ts time=5
weights: languages 4, features 2, performance 2, time 5, platforms 3, cost 3, hiring 2
  87 wrapper
  86 react-native
  72 flutter
  59 kmp
  49 native
```

**The ranking flips.** The wrapper scores 5 on time and React Native 3, so two points of weight are
worth 10 to one and 6 to the other, and a three-point lead becomes a one-point loss. That is the
whole lesson in one run: **the weights are the decision.** The scores describe the tools for this
team; the weights describe what the team wants, and a small change in what it wants can change the
answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l03-flip\" aria-label=\"Two bar charts of the planner's matrix. With time to market weighted 3: React Native 80, wrapper 77, Flutter 66, Kotlin Multiplatform 55, native 47. With time to market weighted 5, and nothing else changed: wrapper 87, React Native 86, Flutter 72, Kotlin Multiplatform 59, native 49. The first two places swap.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">time weighted 3</text><text x=\"112\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react-native</text><rect x=\"120\" y=\"36\" width=\"176\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"302\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">80</text><text x=\"112\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wrapper</text><rect x=\"120\" y=\"68\" width=\"169\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"295\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">77</text><text x=\"112\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flutter</text><rect x=\"120\" y=\"100\" width=\"145\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">66</text><text x=\"112\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kmp</text><rect x=\"120\" y=\"132\" width=\"121\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"247\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55</text><text x=\"112\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">native</text><rect x=\"120\" y=\"164\" width=\"103\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"229\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">47</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">time weighted 5</text><text x=\"472\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wrapper</text><rect x=\"480\" y=\"36\" width=\"191\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"677\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">87</text><text x=\"472\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react-native</text><rect x=\"480\" y=\"68\" width=\"189\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"675\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">86</text><text x=\"472\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flutter</text><rect x=\"480\" y=\"100\" width=\"158\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"644\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">72</text><text x=\"472\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kmp</text><rect x=\"480\" y=\"132\" width=\"130\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"616\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">59</text><text x=\"472\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">native</text><rect x=\"480\" y=\"164\" width=\"108\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"594\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">49</text></svg>", "caption": "One weight moved by two points, and the first two places swap. The scores did not change; what the team wants did."}
```

**Not every weight is that sensitive**, and that is worth knowing too. Say the app gained an
animated timeline, and performance went from 2 to 5:

```
ana@dev:~/planner$ node choose.ts performance=5
weights: languages 4, features 2, performance 5, time 3, platforms 3, cost 3, hiring 2
  92 react-native
  83 wrapper
  78 flutter
  70 kmp
  62 native
```

Native climbs from 47 to 62 and Kotlin Multiplatform from 55 to 70, and React Native stays first, nine
points ahead of the wrapper. A ranking that survives a
large change in a weight is one the team can rely on; a ranking that flips on one point is a sign
the two leaders are close, and the decision rests on that one criterion. Both are useful findings,
and both come from changing a number and running the file again.

## What the program refuses

A typo in a criterion's name would otherwise change nothing and look like an answer, so the program
says so and stops:

```
ana@dev:~/planner$ node choose.ts speed=5
no criterion "speed"; there are: languages, features, performance, time, platforms, cost, hiring
```

**What the matrix cannot do is choose the scores and the weights for you.** A team that sets the
weights after deciding, to make its favourite win, has written a justification rather than a
decision. The honest order is weights first, written down and agreed before anyone totals a column,
then the scores, then the run. Commit the file:

```
ana@dev:~/planner$ git add choose.ts
ana@dev:~/planner$ git commit -q -m "A decision matrix for the planner team"
```
