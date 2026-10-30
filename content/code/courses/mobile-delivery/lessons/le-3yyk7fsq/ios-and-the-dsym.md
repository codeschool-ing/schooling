---
title: iOS, and the dSYM
version: 1
---

**An iOS release binary carries no function names at all; a crash in it is a list of addresses, and
the file that turns them back into names is the dSYM.** It is the same idea as the last two sections
with a different mechanism, and it needs a Mac, so this section is read. *Written from Apple's
documentation on diagnosing issues using crash reports, October 2026; not run.*

## What a raw iOS crash says

A crash report from the system, or from a reporter that did not have the symbols, has frames like
this one, one per line, with the binary's name and two addresses. It is written here to show the
shape, not taken from a real crash:

```
3   Planner   0x0000000102f4a8c4 0x102f30000 + 108740
```

The first address is where the code was running; the second is where the app's binary was loaded in
memory that time. Their difference, 108740 here, is the same on every phone that runs this build,
and it is what the dSYM can look up.

## The dSYM and its UUID

When Xcode archives a release, it writes the debugging information into a separate bundle,
`Planner.app.dSYM`, and strips it from the app. **The binary and its dSYM share a UUID**, written into
both by the linker. A dSYM from any other build, even of the same commit, has a different UUID and is
refused: the same rule as the R8 mapping, enforced by the file itself.

On a Mac, `dwarfdump --uuid` prints the UUID of each, and `atos` turns an address into a function and
a line:

```sh
dwarfdump --uuid Planner.app.dSYM
atos -arch arm64 -o Planner.app.dSYM/Contents/Resources/DWARF/Planner -l 0x102f30000 0x0000000102f4a8c4
```

*Neither was run here.* Xcode's **Organizer** does the same for the crashes Apple collects, and
Crashlytics and Sentry do it for theirs, once the dSYM of each build is uploaded.

## Where the dSYM comes from

- **Xcode's archive** keeps it inside the `.xcarchive`, which the pipeline should keep as an artefact.
- **Bitcode is gone**, since Xcode 14, so the dSYM made by your build is the one that matches what
  Apple distributes. Older instructions about downloading dSYMs from App Store Connect are about
  bitcode builds and no longer apply.
- **Fastlane's `build_app`** writes the dSYM beside the `.ipa`, and both Crashlytics and Sentry have
  an upload command a lane can call after it.

## The same rule, three times

| | the build writes | it is matched by | without it |
|---|---|---|---|
| Android | `mapping.txt` | the mapping's identifier, in the trace | `a.b` and invented line numbers |
| iOS | `.dSYM` | the binary's UUID | addresses |
| React Native | the source map | the bundle it was made with | line 1 and a column |
