---
title: A second release, and the planner one behind
version: 1
---

**A release is a change, a version number that describes it, a note saying what it was, and a publish.**
This one adds a component, which changes nothing that already existed, so it is a minor release:
`0.1.0` to `0.2.0`.

## The change

A progress bar for the week, in the library:

```typescript
// src/components.ts: a fourth component, added at the end
/** Minutes done out of minutes planned, as a bar with a name a screen reader can read. */
export function progressBar(done: number, planned: number): HTMLProgressElement {
  const bar = document.createElement("progress");
  bar.max = Math.max(planned, 1);
  bar.value = Math.min(done, bar.max);
  bar.setAttribute("aria-label", "Minutes done this week");
  bar.textContent = `${duration(done)} of ${duration(planned)}`;
  return bar;
}
```

`<progress>` is the browser's own bar, announced by screen readers as a value out of a maximum.
`Math.max(planned, 1)` avoids a bar whose maximum is zero, the empty-week case lesson 6 taught the library
to expect. Export it from the entry point:

```
ana@dev:~/planner-ui$ sed -i 's/export { actionButton, sessionRow, weekSummary }/export { actionButton, progressBar, sessionRow, weekSummary }/' src/index.ts
ana@dev:~/planner-ui$ npx tsc && echo types ok
types ok
```

## The note

**A changelog is written for the people who will upgrade**, so it says what they gain and what they must
change, not which files moved. One file, newest release first:

```
<!-- CHANGELOG.md -->
# Changelog

## 0.2.0

- Added `progressBar`, which shows minutes done out of minutes planned.

## 0.1.0

- First release: the tokens, the type and spacing scales, two themes, `actionButton`, `sessionRow` and
  `weekSummary`.
```

## The version and the publish

`npm version minor` raises the version in `package.json` and the lockfile, commits them, and tags the commit
`v0.2.0`, so the release can be found in the history:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Add progressBar"
ana@dev:~/planner-ui$ npm version minor
v0.2.0
ana@dev:~/planner-ui$ git log --oneline --decorate -2
bb25678 (HEAD -> main, tag: v0.2.0) 0.2.0
4cb7a84 Add progressBar
ana@dev:~/planner-ui$ npm run build > /dev/null && npm publish 2>&1 | tail -1
+ @planner/ui@0.2.0
```

## The planner, told it is behind

In the planner, `npm outdated` compares what is installed with what the registry has:

```
ana@dev:~/planner$ npm outdated @planner/ui; echo $?
Package      Current  Wanted  Latest  Location                  Depended by
@planner/ui    0.1.0   0.1.0   0.2.0  node_modules/@planner/ui  planner
1
```

**Current** is what is installed; **Wanted** is the newest the range in `package.json` allows, the same
`0.1.0` because the planner pins it exactly; **Latest** is the newest published. The exit code is 1, which
is how a pipeline could notice a dependency falling behind. Upgrading is one command and a commit, made on
purpose, which is the point of the pin:

```
ana@dev:~/planner$ npm install --save-exact @planner/ui@0.2.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ git commit -qam "@planner/ui 0.2.0"
ana@dev:~/planner$ git log --oneline -1
f7e724d @planner/ui 0.2.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A timeline of @planner/ui versions: 0.1.0, then 0.2.0. The planner is pinned at 0.1.0; npm outdated reports Current 0.1.0, Wanted 0.1.0 and Latest 0.2.0. Upgrading is a commit that installs 0.2.0.\"><line x1=\"40\" y1=\"60\" x2=\"680\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,60.0 672.6,63.1 672.6,56.9\" fill=\"var(--wire)\"></polygon><text x=\"680\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">releases</text><rect x=\"120\" y=\"46\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.1.0</text><rect x=\"420\" y=\"46\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.2.0</text><text x=\"460\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ progressBar</text><rect x=\"100\" y=\"112\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the planner</text><line x1=\"160\" y1=\"112\" x2=\"160\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,78.0 163.1,85.4 156.9,85.4\" fill=\"var(--amber)\"></polygon><text x=\"240\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Current 0.1.0 · Wanted 0.1.0 · Latest 0.2.0</text><text x=\"240\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">upgrading is a commit, made on purpose</text></svg>", "caption": "A pinned consumer stays where it is until somebody moves it, and npm outdated says how far behind it is."}
```

## Tools that do the bookkeeping

**Changesets** is the tool most JavaScript libraries use for this: each pull request carries a small file
naming the packages it changes and whether the change is a patch, minor or major, with a line for the
changelog. At release time one command turns the accumulated files into version numbers and changelog
entries, across every package of a monorepo at once. It was not run for this course; its commands ask
questions at a terminal, and what it automates is exactly the three steps above.
