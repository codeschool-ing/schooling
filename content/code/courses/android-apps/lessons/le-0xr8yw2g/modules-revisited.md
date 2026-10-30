---
title: One module, and when to stop having one
version: 1
---

**Lesson 1 section 06 promised to return to modules, and the answer for the planner is still one.**
A module pays for itself in two ways, both named there. It recompiles less, because Gradle rebuilds only the modules a change touches and the ones that depend on them. And it enforces boundaries, because code cannot use a class from a module it does not declare. Neither has bitten the planner
yet: its build is quick, and one person holds all of it in their head.

## The signs that one module is no longer enough

- **A build you wait for.** The release build of section 04 took 1 minute 16 seconds, and much
  of that is R8 reading everything, and that is unavoidable; but if a *debug* build after a one-line change starts taking
  more than a few seconds, the compiler is redoing work a module boundary would have saved.
- **A rule nobody can enforce.** "The screens never talk to Room directly, only through the
  repository" is lesson 16's architecture. In one module it is a convention a reviewer has to catch;
  with `:core:data` and `:feature:sessions` as separate modules, a screen that imports a DAO does not
  compile.
- **A second app.** A tablet or watch version of the planner would share the model and the
  repository and nothing of the screens, which is a module boundary drawn for you.

## How the split usually goes

Google's architecture guidance for modular apps describes the common shape: `:app` at the top,
assembling everything; `:feature:…` modules, one per screen or flow, that depend on `:core:…`
modules but never on each other; and `:core:data`, `:core:model` and `:core:ui` at the bottom. Each
is a directory with its own `build.gradle.kts`, a line in `settings.gradle.kts`, and the
`com.android.library` plugin instead of `com.android.application`.

**Not run** for the planner: splitting it would add build files and teach nothing a lesson of this
course needs, and an example that does not fit is made smaller, not larger. The catalogue of lesson
1 section 05 was written to make the split cheap when it comes, because every module reads the
same `libs.versions.toml`.

## Where the course ends

Twenty-two lessons ago the planner was eight files and a sentence on a screen. It now has screens in Compose that survive rotation, state in ViewModels, and data from a server and from Room behind one repository. It has background sync that outlives the app, a reminder that asks before it notifies, tests at three levels, and a signed, shrunk bundle that Google Play would accept. The courses that follow on
this track, `mobile-offline` and `mobile-delivery`, take the same planner further without assuming
which of the three platforms you chose.
