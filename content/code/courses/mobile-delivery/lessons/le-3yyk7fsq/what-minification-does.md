---
title: What a release build does to your names
version: 1
---

**A release build is not your code with the debugging switched off; it is your code rewritten to be
smaller, and the rewriting is what makes its crashes unreadable.** Every platform does it, for the
same two reasons: a smaller download, lesson 18, and a faster start, lesson 15.

| | the tool | what it does to names | what it leaves behind |
|---|---|---|---|
| Android | **R8**, run by Gradle when `isMinifyEnabled = true` | renames classes, methods and fields to `a`, `b`, `c`; inlines small methods into their callers; removes what nothing uses | `mapping.txt` |
| iOS | the compiler and the linker, with symbols **stripped** from the binary | removes function names altogether; a crash names addresses | a `.dSYM` bundle |
| React Native | **Metro** or esbuild, then **Hermes** compiling to bytecode | renames variables and functions, joins everything into one line | a **source map** |

## Three effects that change what a trace says

- **Renaming.** `WeekViewModel.totalMinutes` becomes `a.b`. The trace is accurate and says nothing.
- **Inlining.** A short method is copied into the method that calls it, so it no longer exists as a
  frame of its own. A trace from a release build can be **shorter** than the same crash in debug, with
  the function where the bug is missing from it entirely.
- **Joining lines.** Minified JavaScript is one line, so every frame says line 1, and only the column
  distinguishes them.

## The rule this lesson keeps repeating

**The file that undoes the rewriting is produced by the build, and only that build's file works.**
Two builds of the same commit can choose different short names and different inlining. So the
mapping, the dSYM or the source map is kept beside the build that shipped, and uploaded to the crash
reporter as part of the release, lesson 12. The next two sections show what that file does, with the
real tools, on your computer.
