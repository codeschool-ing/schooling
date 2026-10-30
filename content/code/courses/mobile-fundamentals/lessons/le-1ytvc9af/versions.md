---
title: Two numbers on every release
version: 1
---

**Every build carries two numbers: one people read, and one the store compares.** The common
mistake is to think there is one version number. There are two on each platform, they do different
jobs, and only one of them is allowed to do anything other than grow.

| | the number people read | the number the store compares |
|---|---|---|
| Android | `versionName`, a string such as `1.10.0` | `versionCode`, a positive integer |
| iOS | `CFBundleShortVersionString`, such as `1.10.0` | `CFBundleVersion`, the build number |

**Android's `versionCode` is the strict one.** Android's documentation on versioning, read on
30 October 2026, calls it "a positive integer used as an internal version number" and says that "higher numbers" mean "more recent versions". The system uses it "to protect against
downgrades by preventing users from installing an APK with a lower versionCode than the version
currently installed". Play adds two rules: "You can't upload an APK to the Play Store with a
versionCode you have already used", and "the greatest value Google Play allows for versionCode is
2100000000". The usual practice it describes is to start at 1 and add one for every release, minor or
major, which is why the code "doesn't necessarily resemble the app release version". The
`versionName` is "the only value displayed to users", and Android does not compare it at all.

**iOS's two keys are both made of numbers and dots.** Apple's documentation describes
`CFBundleShortVersionString` as "a user-visible string" whose "required format is three
period-separated integers, such as 10.14.1", and `CFBundleVersion` as "a machine-readable string
composed of one to three period-separated integers", where a missing part counts as zero: "10.5
specifies 10.5.0". Apple's page on `CFBundleVersion` says the App Store requires it.

## Why "1.10.0" is not smaller than "1.9.2"

**Compared as text, version numbers sort wrongly, and the bug is an easy one to ship.** As
strings, `"1.10.0"` comes before `"1.9.2"`, because the character `1` comes before `9`. As versions,
1.10 is the tenth minor release and 1.9 the ninth. A release script that compares the two as text
decides the new version is older, or worse, decides an older one is newer. The fix is to split on the
dots and compare each part as a number, which is what the check below does.

## A release check for the planner

This program takes a release candidate and the version the store already has, and lists every reason
the candidate must not ship: a build number that does not grow, one outside what Play accepts, or a
version name that goes backwards. The build rule is the stores'; the name rule is the planner's own,
because the name is what a student reads in the store and a version that counts down looks like a
mistake. Save it as `version.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "version.ts", "parts": [{"code": "// version.ts: is this release candidate newer than what the store already has?\ntype Release = { name: string; build: number }; // versionName + versionCode, or the two iOS keys\n", "note": "One shape for both platforms: `name` is `versionName` or `CFBundleShortVersionString`, `build` is `versionCode` or `CFBundleVersion`. The build is a plain integer here, as Android's is."}, {"code": "// \"1.10.0\" -> [1, 10, 0]; a missing part counts as 0, so \"1.10\" equals \"1.10.0\".\nfunction parts(name: string): number[] {\n  if (!/^\\d+(\\.\\d+){0,2}$/.test(name)) throw new Error(`not a version: ${name}`);\n  const p = name.split(\".\").map(Number);\n  while (p.length < 3) p.push(0);\n  return p;\n}\n", "note": "A version is up to three numbers separated by dots, and anything else is refused loudly. Padding with zeros is Apple's rule for `CFBundleVersion`: \"10.5 specifies 10.5.0\"."}, {"code": "// Negative if a is older, 0 if the same, positive if a is newer: part by part, as numbers.\nexport function compare(a: string, b: string): number {\n  const [x, y] = [parts(a), parts(b)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] - y[i];\n  return 0;\n}\n", "note": "The comparison that text cannot do: 10 against 9 as numbers, part by part, stopping at the first difference."}, {"code": "// Why the candidate must not ship; an empty list means it may. The build rule is the stores';\n// the name rule is ours, because the name is the number people read.\nexport function problems(candidate: Release, published: Release): string[] {\n  const out: string[] = [];\n  if (!Number.isInteger(candidate.build) || candidate.build < 1 || candidate.build > 2100000000) { // Play's ceiling\n    out.push(`build ${candidate.build} is not an integer from 1 to 2100000000`);\n  } else if (candidate.build <= published.build) {\n    out.push(`build ${candidate.build} is not higher than the published ${published.build}`);\n  }\n  if (compare(candidate.name, published.name) < 0) {\n    out.push(`version ${candidate.name} goes back from the published ${published.name}`);\n  }\n  return out;\n}\n", "note": "Every reason at once, not just the first, so one run says everything wrong with a candidate. The ceiling of 2100000000 is Play's; the comment says whose rule each check is."}, {"code": "const published: Release = { name: \"1.9.2\", build: 41 };\nconsole.log(`as text, \"1.10.0\" > \"1.9.2\" is ${\"1.10.0\" > \"1.9.2\"}`);\nconsole.log(`as versions, compare(\"1.10.0\", \"1.9.2\") is ${compare(\"1.10.0\", \"1.9.2\")}`);\nfor (const c of [\n  { name: \"1.10.0\", build: 42 },\n  { name: \"1.10.0\", build: 41 },\n  { name: \"1.9.1\", build: 43 },\n  { name: \"1.9.2\", build: 43 },\n]) {\n  const p = problems(c, published);\n  console.log(`${c.name} (${c.build}): ${p.length === 0 ? \"ok\" : \"REFUSED, \" + p.join(\"; \")}`);\n}", "note": "The published release, the text comparison that goes wrong, and four candidates: one fine, one reusing a build number, one counting down, and one rebuild."}]}
```

```
ana@dev:~/planner$ node version.ts
as text, "1.10.0" > "1.9.2" is false
as versions, compare("1.10.0", "1.9.2") is 1
1.10.0 (42): ok
1.10.0 (41): REFUSED, build 41 is not higher than the published 41
1.9.1 (43): REFUSED, version 1.9.1 goes back from the published 1.9.2
1.9.2 (43): ok
```

**The first line is the bug, caught.** As text, `"1.10.0" > "1.9.2"` is `false`; as versions,
`compare` says the first is newer. Then four candidates against a published 1.9.2, build 41. `1.10.0`
with build 42 may go. The same name with build 41 is refused, because 41 was used, and on Play that
upload would fail. `1.9.1` with build 43
has a fine build number and a name that counts down. And `1.9.2` with build 43 may go, which is
the case of a rebuild: the same version, fixed and uploaded again, with a new build number.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l20-numbers\" aria-label=\"Version numbers over three releases of the planner, as a timeline. Release 1.9.2, build 41, shipped. Then 1.10.0, build 42, rejected in review and never shipped, drawn dashed. Then 1.10.0 again, build 43, shipped. Then 1.10.1, build 44, shipped. The name people read repeats when a build is redone; the build number never repeats and only grows.\"><defs><marker id=\"l20-numbers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-numbers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the name people read</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the number the store compares</text><path d=\"M190 196 L700 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-wire)\"></path><rect x=\"200\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.9.2</text><rect x=\"200\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">41</text><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">shipped</text><path d=\"M300 150 L325 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"325\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.0</text><rect x=\"325\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">42</text><text x=\"375\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">rejected in review</text><path d=\"M425 150 L450 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"450\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.0</text><rect x=\"450\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">43</text><text x=\"500\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">shipped</text><path d=\"M550 150 L575 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"575\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.1</text><rect x=\"575\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">44</text><text x=\"625\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">shipped</text></svg>", "caption": "Three releases and four builds. The name 1.10.0 appears twice, because the rejected build was fixed and sent again; the build number moved on and 42 is gone for good."}
```

**The build number counts every build that reached the store, not every release.** In the figure,
1.10.0 went up twice: build 42 was rejected in review, and the fix went up as build 43 with the same
name. Nobody outside the team ever saw 42, and it still used up its number for good. That is why a team
lets the build pipeline assign the build number rather than a person, and why `mobile-delivery`
lesson 9 spends a lesson on the semantics people read into the other number.
