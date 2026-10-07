---
title: Versions and ranges
version: 1
---

**A version number is `MAJOR.MINOR.PATCH`, and each part is a promise about what changed.** This
convention is called **semantic versioning**, or semver, and the whole npm ecosystem leans on it:

- **PATCH** goes up for a fix. Code that worked keeps working;
- **MINOR** goes up when something is added. Code that worked keeps working, and new code can use
  the addition;
- **MAJOR** goes up when something that worked stops working: a function renamed, an argument
  removed, a default changed.

The lab's registry has five versions of `shelf-slug`, one of each kind of change:

```
ana@dev:~/js/first$ npm view shelf-slug versions
[ '1.0.0', '1.1.0', '1.1.1', '1.2.0', '2.0.0' ]
```

`1.1.0` added a `max` option, `1.1.1` fixed accented letters, `1.2.0` added a `sep` option, and
`2.0.0` renamed `slug` to `toSlug`.

## Ranges

A dependency in `package.json` is a range, not a version, and `npm view` with a range lists every
published version inside it:

```
ana@dev:~/js/first$ npm view shelf-slug@1.1.0 version
1.1.0
ana@dev:~/js/first$ npm view shelf-slug@~1.1.0 version
shelf-slug@1.1.0 '1.1.0'
shelf-slug@1.1.1 '1.1.1'
ana@dev:~/js/first$ npm view shelf-slug@^1.1.0 version
shelf-slug@1.1.0 '1.1.0'
shelf-slug@1.1.1 '1.1.1'
shelf-slug@1.2.0 '1.2.0'
ana@dev:~/js/first$ npm view shelf-slug@latest version
2.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Five published versions of shelf-slug across the top, and four ways of asking for it down the side. The exact version 1.1.0 accepts only itself. The tilde range ~1.1.0 accepts 1.1.0 and 1.1.1 and installs 1.1.1. The caret range ^1.1.0 accepts 1.1.0, 1.1.1 and 1.2.0 and installs 1.2.0. The tag latest is 2.0.0. No range that starts at 1 ever reaches 2.0.0.\"><rect x=\"208\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.0.0</text><rect x=\"303\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.1.0</text><rect x=\"398\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.1.1</text><rect x=\"493\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.2.0</text><rect x=\"588\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2.0.0</text><text x=\"320\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">patch: a fix</text><text x=\"450\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minor: something added</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">major: something broken</text><text x=\"30\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.1.0</text><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this version only</text><rect x=\"299\" y=\"92\" width=\"92\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"305\" y=\"96\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.1.0</text><text x=\"30\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">~1.1.0</text><text x=\"30\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fixes only</text><rect x=\"299\" y=\"136\" width=\"187\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"345\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.0</text><rect x=\"400\" y=\"140\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.1.1</text><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">^1.1.0</text><text x=\"30\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fixes and additions</text><rect x=\"299\" y=\"180\" width=\"282\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"345\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.0</text><text x=\"440\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.1</text><rect x=\"495\" y=\"184\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.2.0</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">latest</text><text x=\"30\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">whatever is newest</text><rect x=\"584\" y=\"224\" width=\"92\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"590\" y=\"228\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">2.0.0</text></svg>", "caption": "A range is the set of versions you accept; the manager installs the newest one inside it."}
```

- **`1.1.0`**, with nothing in front, is exactly that version;
- **`~1.1.0`**, the tilde, accepts patches: `1.1.x`, from `1.1.0` up;
- **`^1.1.0`**, the caret, accepts patches and additions: anything `1.x` from `1.1.0` up. This is
  what `npm install` writes unless you tell it otherwise;
- **`latest`** is a tag, not a range: a name the publisher points at one version, usually the newest.

When the manager installs, it takes **the newest version inside the range**. The caret is the
common choice because it brings fixes and additions without asking, and stops before the one kind
of change that is allowed to break you.

A range that starts at `0` is stricter: `^0.3.1` accepts `0.3.x` and not `0.4.0`, because before
`1.0.0` semver treats every minor version as possibly breaking.

## Behind the range

`npm outdated` compares what is installed with the range and with the newest release. Here ana
installs an old version on purpose:

```
ana@dev:~/js/first$ npm install shelf-slug@1.0.0

changed 1 package in 506ms
ana@dev:~/js/first$ node slug.js
grande-sertão:-veredas
ana@dev:~/js/first$ npm outdated
Package     Current  Wanted  Latest  Location                 Depended by
shelf-slug    1.0.0   1.2.0   2.0.0  node_modules/shelf-slug  first
```

**Current** is what is in `node_modules`. **Wanted** is the newest version the range in
`package.json` accepts. **Latest** is the newest published. `npm update` would move her to Wanted.
Moving to Latest means crossing a major version, and that is never automatic. `npm outdated` ends
with exit status 1 when something is behind, so a build can use it as a check.

The `1.0.0` output also shows the accent bug that `1.1.1` fixed: `sertão` kept its `ã`.

## Crossing a major version

Asking for `@2` installs `2.0.0` and rewrites the range to `^2.0.0`:

```
ana@dev:~/js/first$ npm install shelf-slug@2

changed 1 package in 508ms
ana@dev:~/js/first$ node slug.js 2>&1 | head -n 5
file:///home/ana/js/first/slug.js:1
import { slug } from "shelf-slug";
         ^^^^
SyntaxError: The requested module 'shelf-slug' does not provide an export named 'slug'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:226:21)
```

The import of `slug` fails before a line of the program runs, because ES module imports are checked
when the module loads. This is the break the major number warned about. **Read the changelog before
moving a major version**, then change the code, here to `toSlug`, in the same commit.

Semver is a promise made by people, and people get it wrong. A patch that breaks something happens.
The lockfile, next, is what keeps a mistake like that from reaching you without your noticing.
