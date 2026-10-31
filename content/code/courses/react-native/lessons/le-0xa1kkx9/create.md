---
title: A local module, created
version: 1
---

`create-expo-module` writes a module from Expo's template. With `--local` it writes it inside the project,
in `modules/`, rather than as a package of its own; autolinking finds it there, as it finds a library in
`node_modules`. The options answer the questions the tool would otherwise ask:

```
ana@dev:~/planner$ npx create-expo-module@58.0.3 week-start --local --barrel --name WeekStart --package org.example.weekstart --platform apple android web --features Function --description 'The first day of the week' > /dev/null 2>&1
ana@dev:~/planner$ find modules -type f | sort
modules/week-start/CHANGELOG.md
modules/week-start/LICENSE
modules/week-start/android/build.gradle
modules/week-start/android/src/main/AndroidManifest.xml
modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt
modules/week-start/expo-module.config.json
modules/week-start/index.ts
modules/week-start/ios/WeekStart.podspec
modules/week-start/ios/WeekStartModule.swift
modules/week-start/src/WeekStart.types.ts
modules/week-start/src/WeekStartModule.ts
modules/week-start/src/WeekStartModule.web.ts
```

- **`expo-module.config.json`** names the module's class on each platform; it is what autolinking reads.
- **`android/`** is a small Gradle library: `build.gradle`, a manifest, and one Kotlin class under the
  package given as `--package`.
- **`ios/`** has the Swift class and a **podspec**, the description CocoaPods needs to build it into the
  iOS project.
- **`src/`** is the JavaScript face: the module's type on phones, its web version, and a file for shared
  types. `index.ts`, from `--barrel`, re-exports them, so the app imports `modules/week-start`.

`--features Function` asked for an example of one synchronous function, which is what this module is.
The template's example says hello; the next section replaces it.
