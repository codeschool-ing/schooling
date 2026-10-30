---
title: The same app, built two ways
version: 1
---

**Everything in this course so far ran as a development build or a development bundle.** That is the app
a developer sees, and it differs from the one people install in ways that are easy to forget:

| | development | release |
|---|---|---|
| JavaScript | text, served by Metro, reloaded on save | Hermes bytecode, inside the app |
| `__DEV__` | `true` | `false`, and code under `if (__DEV__)` is removed |
| warnings and checks | on: LogBox, prop and key warnings, extra invariants | off |
| names | as written | minified, in the parts the minifier may rename |
| speed | slower, by design | as fast as it will be |

**A bug that appears only in release is almost always one of four things**: a check that existed only in
development and was hiding a mistake; a value fixed at build time that was different on the machine that
built the release; code that depended on a name the minifier changed; or data the release meets and
development never did. This lesson shows the second and the fourth for real, since they are the common
ones.

`npx expo export` builds the same bundle a build would put in the app, and `--dev` builds the development
one instead. Export both for Android and compare:

```
ana@dev:~/planner$ npx expo export --platform android --dev --output-dir dist-dev > /dev/null 2>&1
ana@dev:~/planner$ npx expo export --platform android --output-dir dist-release > /dev/null 2>&1
ana@dev:~/planner$ du -h dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*
8.3M	dist-dev/_expo/static/js/android/index-d41d8cd98f00b204e9800998ecf8427e.js
3.7M	dist-release/_expo/static/js/android/index-b1b560afedabb7d4252211b95eff52e0.hbc
ana@dev:~/planner$ grep -a -c 'Text strings must be rendered within a <Text>' dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*
dist-dev/_expo/static/js/android/index-d41d8cd98f00b204e9800998ecf8427e.js:1
dist-release/_expo/static/js/android/index-b1b560afedabb7d4252211b95eff52e0.hbc:0
```

**8.3 megabytes of JavaScript text against 3.7 of bytecode.** The development bundle carries the code for
warnings, for Fast Refresh and for the debugger; the release one is minified and compiled. And the sentence
lesson 4 met, *Text strings must be rendered within a `<Text>` component*, is in the development bundle once
and in the release bundle not at all: the check that produces it is development-only. A mistake it would
have caught is simply there, in release, doing whatever it does.
