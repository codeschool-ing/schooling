---
title: Version names and version numbers
version: 1
---

**Every release has two versions, one for people and one for the stores.**

| | for people | for the store |
|---|---|---|
| in `app.json` | `version`, such as `"1.2.0"` | `android.versionCode`, `ios.buildNumber` |
| what it is | what the store page shows | a number that only goes up |
| rule | anything readable | every upload higher than the last, or it is refused |

`1.2.0` can be uploaded several times while testing, each with a higher `versionCode`; the store page keeps
showing `1.2.0`. Forgetting to raise the number is the commonest rejection of an upload, which is why
`eas.json`'s `autoIncrement` exists.

**A build also has a *runtime version*, which lesson 21 needs.** It describes the native side, the libraries
with native code and their versions, and it decides which over-the-air updates a build may receive. The
version number says when; the runtime version says what the build can run.
