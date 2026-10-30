---
title: Product flavours: two apps from one source
version: 1
---

**A flavour is a version of the app that differs in what it is, where a build type differs in how it
is built.** The planner gets two: `play`, the one Google Play distributes, and `direct`, the same app
handed out as a file from the planner's own website for students whose phone has no Play Store. Two
flavours times two build types is four variants, and Gradle names each one by putting the two
together: `playDebug`, `playRelease`, `directDebug`, `directRelease`.

The two flavours share every line of code. What separates them is in section 02's build file:
`direct` has its own `applicationIdSuffix`, so both can be installed on one phone, and each sets its
own value of a constant in a generated class:

```
ana@vm:~/planner$ find app/build/generated -name BuildConfig.java | sort
app/build/generated/source/buildConfig/direct/debug/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/direct/release/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/play/debug/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/play/release/com/example/planner/BuildConfig.java
ana@vm:~/planner$ grep -h -E "APPLICATION_ID|UPDATES_FROM" app/build/generated/source/buildConfig/direct/debug/com/example/planner/BuildConfig.java
  public static final String APPLICATION_ID = "com.example.planner.direct.debug";
  public static final String UPDATES_FROM = "the planner's website";
```

**`BuildConfig` is generated per variant**, four times, and the app reads `BuildConfig.UPDATES_FROM`
like any constant. In `direct`, the planner can say "updates come from the planner's website" and
check that page; in `play`, the store updates it and the planner says nothing about it. The
`APPLICATION_ID` beside it is the one this variant installs as, suffixes included.

## When a flavour is the right tool, and when it is not

**Flavours fit what is decided at build time and differs per distribution**: where updates come
from, which server a test build talks to, which payment library a store requires. A flavour can also
carry whole files of its own: a `src/direct/` folder beside `src/main/` holds code or resources only
the `direct` variants receive, merged over `main` the way lesson 1's `values-pt` was merged over
`values`.

**Flavours do not fit what a student chooses**, such as a premium tier: two apps for the same person
is two installs, two sets of data and two store listings. That belongs in the running app. And every
flavour doubles the variants to build and test: two dimensions of three flavours each, with two build
types, is eighteen. A team adds one when the difference cannot live anywhere else.
