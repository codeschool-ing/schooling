---
title: The wasteful kind, and how to know you have it
version: 1
---

**Recomposition is not a cost to minimise; wasteful recomposition is.** Compose is built to run
composables again, and a composable that reruns on every change it reads is doing its job. The four sections before this one each showed a way the work grows beyond what the screen needs. A parent reads a value only to pass it on (section 02), or an argument is rebuilt on every run (section 03). A type is one the compiler cannot trust (section 04), or a source changes far more often than the result (section 05). And section 06 showed the one that is not about speed at all, a remembered value that
lands on the wrong item.

**Measure before changing anything.** Every fix above costs some readability: a lambda instead of a
value, a `remember` around an argument, a line in a stability file that must stay true. They are
worth it where a composable runs on every frame, during a scroll, an animation or a drag, and almost
never where it runs once per tap. The counting with `SideEffect` used in this lesson works in any
test. Android Studio's Layout Inspector shows recomposition and skip counts for each composable of a
running app, according to Google's documentation; **not run** here, since it needs Studio and a
device.

**Measure a release build.** A debug build runs the Compose runtime without the optimisations R8
applies, and Google's documentation on Compose performance says to judge performance on a release
build, with lesson 22's settings. A screen that stutters in debug may be smooth in release, and the
opposite is rare.

## A short list to keep

- Read state as low in the tree as the value is used; pass a lambda when a value changes every frame.
- Do not build objects in the body to pass them on; `remember` them, or pass what they are built from.
- Read the compiler's report before deciding a type is the problem, and add a class to the stability
  file only when its documentation promises it never changes.
- Use `derivedStateOf` when a result changes much less often than its source, and only then.
- Give every item drawn in a loop a stable, unique key.
