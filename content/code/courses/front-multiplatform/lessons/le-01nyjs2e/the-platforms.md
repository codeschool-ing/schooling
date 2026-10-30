---
title: The Android and iOS projects
version: 1
---

**Each platform is one more package and one command.** The package carries that platform's half of
the bridge, and `cap add` writes a native project that uses it:

```
ana@dev:~/planner$ npm install -E @capacitor/android@8.5.3 @capacitor/ios@8.5.3

added 2 packages, and audited 120 packages in 676ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npx cap add android
✔ Adding native android project in android in 52.63ms
✔ add in 53.07ms
✔ Copying web assets from dist to android/app/src/main/assets/public in 5.73ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 687.24μs
✔ copy android in 16.35ms
✔ Updating Android plugins in 1.39ms
✔ update android in 17.01ms
✔ Syncing Gradle in 390.32μs
[success] android platform added!
Follow the Developer Workflow guide to get building:
https://capacitorjs.com/docs/basics/workflow
ana@dev:~/planner$ npx cap add ios
✔ Adding native Xcode project in ios in 26.97ms
✔ add in 27.46ms
✔ Copying web assets from dist to ios/App/App/public in 4.46ms
✔ Creating capacitor.config.json in ios/App/App in 493.88μs
✔ copy ios in 14.36ms
✔ Updating iOS plugins in 1.20ms
[info] All Capacitor plugins have a Package.swift file and will be included in Package.swift
[info] Writing Package.swift
✔ update ios in 15.71ms
[success] ios platform added!
Follow the Developer Workflow guide to get building:
https://capacitorjs.com/docs/basics/workflow
```

Each `cap add` did the same three steps, and the lines say which: **it wrote a native project**, it
**copied `dist/`** into it, and it **updated the plugins** the project knows about, none yet. The
Android project uses Gradle, Android's build tool, which is why "Syncing Gradle" is the last step. The
iOS one lists its native dependencies in `Package.swift`, for Xcode's Swift Package Manager.

## What arrived

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
?? android/
?? capacitor.config.ts
?? ios/
ana@dev:~/planner$ ls android ios/App
android:
app
build.gradle
capacitor-cordova-android-plugins
capacitor.settings.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle
variables.gradle

ios/App:
App
App.xcodeproj
CapApp-SPM
```

**Two folders, `android/` and `ios/`, and both are yours now.** `android/` is a Gradle project that
Android Studio opens: `app/` is the app itself and the files around it configure the build. `ios/App`
holds `App.xcodeproj`, which Xcode opens, `App/` with the app's Swift files, and `CapApp-SPM`, the
Swift package that pulls in Capacitor. Lesson 3 opens both and says which files you will edit.

**Both go into git**, which is the opposite of what people expect from generated code. Capacitor
writes them once and never again. From now on you change them: an app icon, a permission, a line of
native code. A folder that gets regenerated is a build output and belongs in `.gitignore`; a folder
you edit is source.

## `cap doctor`

`npx cap doctor` checks the versions and each platform's tools, and prints a line per platform. On
the Linux machine this course was recorded on, the iOS line is this one:

```
ana@dev:~/planner$ npx cap doctor | grep -E "installed|Xcode"
[error] Xcode is not installed
```

That `[error]` is the boundary lesson 1 declared, said by the tool itself: there is no Xcode on Linux,
so the iOS project can be generated and edited here, and built only on a Mac. The Android line
reports success on the same machine, which only means its project is in order: it does not check
that an Android SDK exists, and lesson 3 meets the moment one is needed.
