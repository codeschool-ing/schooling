---
title: Package.resolved, and what a version number promises
version: 1
---

The manifest says which versions are **acceptable**. It does not say which one is **in use**, and two
people building on two different days could otherwise get two different versions: the one that was
newest on each day. **`Package.resolved` records the exact choice**, and SwiftPM wrote it during
section 04's `resolve`:

```
ana@vm:~/sw/l19/planner$ cat Package.resolved
{
  "originHash" : "94239d2734703aadf2b5c92720b93d6ed3ea3885f2fbda595555fb7c04f244bf",
  "pins" : [
    {
      "identity" : "swift-argument-parser",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-argument-parser",
      "state" : {
        "revision" : "6a52f3251125d74daf04fcbd5e6f08a75d074382",
        "version" : "1.8.2"
      }
    }
  ],
  "version" : 3
}
```

One **pin** per dependency: where it came from, the version chosen, and the git **revision**, the
commit that version's tag pointed at. The revision is the real identity; a tag can in principle be
moved to another commit, and the pin would notice. **Commit `Package.resolved` to version control
for an app or a tool**, so that everybody who builds it, and every CI run, uses the same code. A
library is the exception: the app that uses it resolves the whole graph, and a library's own pins
are ignored there.

`show-dependencies` draws the graph, which here is one package with no dependencies of its own:

```
ana@vm:~/sw/l19/planner$ swift package show-dependencies
.
└── swift-argument-parser<https://github.com/apple/swift-argument-parser@1.8.2>(traits: default)
```

## What `from:` allows

Swift packages use **semantic versioning**: `MAJOR.MINOR.PATCH`, where a patch fixes bugs, a minor
version adds things without breaking anything, and a major version may break code that used the
last one. The requirement in the manifest is a range over those numbers:

| requirement | accepts | the reasoning |
|---|---|---|
| `from: "1.6.0"` | 1.6.0 up to, not including, 2.0.0 | any compatible version, the usual choice |
| `.upToNextMinor(from: "1.6.0")` | 1.6.0 up to, not including, 1.7.0 | only bug fixes on top of 1.6 |
| `exact: "1.6.2"` | 1.6.2 and nothing else | rarely right in a manifest: `Package.resolved` already pins |
| `branch: "main"` | whatever that branch holds now | not a version at all; a package that uses one cannot itself be depended on by version |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-ranges\" aria-label=\"A line of the tags of swift-argument-parser from 1.5.0 to 1.8.2, and 2.0.0, which does not exist yet, at the end. The range from: 1.6.0 covers 1.6.0 up to just before 2.0.0, and resolve picked 1.8.2, the newest. The range upToNextMinor from 1.6.0 covers 1.6.0 to 1.6.2, and resolve picked 1.6.2.\"><path d=\"M50 70 L672 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 64 L70 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.5.0</text><path d=\"M122 64 L122 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"122\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.5.1</text><path d=\"M174 64 L174 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"174\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.0</text><path d=\"M226 64 L226 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"226\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.1</text><path d=\"M278 64 L278 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.2</text><path d=\"M330 64 L330 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.0</text><path d=\"M382 64 L382 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.1</text><path d=\"M434 64 L434 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"434\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.2</text><path d=\"M486 64 L486 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"486\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.0</text><path d=\"M538 64 L538 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"538\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.1</text><path d=\"M590 64 L590 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.2</text><path d=\"M652 64 L652 76\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"652\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2.0.0</text><text x=\"652\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">not released</text><rect x=\"166\" y=\"110\" width=\"482\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"174\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">from: \"1.6.0\"</text><rect x=\"585\" y=\"96\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">newest allowed: 1.8.2</text><rect x=\"166\" y=\"180\" width=\"152\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"328\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.upToNextMinor(from: \"1.6.0\")</text><rect x=\"273\" y=\"166\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"278\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">newest allowed: 1.6.2</text><text x=\"360\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">The manifest draws the range; resolve picks the newest tag inside it,</text><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">and Package.resolved keeps that pick until swift package update.</text></svg>", "caption": "Two requirements over the same tags. A version requirement is a range, and the pin is one point inside it, chosen once and kept."}
```

Narrowing the range moves the pin, on the next `resolve`. `sed -i` edits the manifest in place,
turning `from: "1.6.0"` into `.upToNextMinor(from: "1.6.0")`:

```
ana@vm:~/sw/l19/planner$ sed -i 's/from: "1.6.0"/.upToNextMinor(from: "1.6.0")/' Package.swift
ana@vm:~/sw/l19/planner$ grep argument-parser Package.swift
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.6.0")),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
ana@vm:~/sw/l19/planner$ swift package resolve
Updating https://github.com/apple/swift-argument-parser
Updated https://github.com/apple/swift-argument-parser (0.57s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.6.2 (0.80s)
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.6.2
```

1.6.2 is the newest 1.6 release. Now put the range back as it was, and resolve again:

```
ana@vm:~/sw/l19/planner$ sed -i 's/.upToNextMinor(from: "1.6.0")/from: "1.6.0"/' Package.swift
ana@vm:~/sw/l19/planner$ swift package resolve
ana@vm:~/sw/l19/planner$ grep '"version" : "1' Package.resolved
        "version" : "1.6.2"
```

**`resolve` printed nothing and kept 1.6.2**, although 1.8.2 is allowed again and newer. That is the
whole purpose of the file: a pin that satisfies the manifest is never moved by `resolve` or by
`build`, so nobody's dependency changes under them because somebody else published a release. **The
version moves only when you ask, with `swift package update`:**

```
ana@vm:~/sw/l19/planner$ swift package update
Updating https://github.com/apple/swift-argument-parser
Updated https://github.com/apple/swift-argument-parser (0.36s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.8.2 (0.38s)
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.8.2
ana@vm:~/sw/l19/planner$ grep '"version" : "1' Package.resolved
        "version" : "1.8.2"
```

Update when you have time to read what changed and run the tests, and commit the new
`Package.resolved` with the change it caused, so the history says which version bump came with
which fix. Section 04's `--help` page is the same at 1.6.2 and 1.8.2, and that is what a minor
version promises; a major version is where you read the release notes before updating.
