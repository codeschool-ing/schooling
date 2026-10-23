---
title: Native projects that are generated, every time
version: 1
---

**Here Expo takes the opposite decision to Capacitor's.** Lesson 3 put `android/` and `ios/` into git,
because Capacitor writes them once and then they are yours. Expo calls its approach **Continuous Native
Generation**: the native projects are generated from `app.json` and the packages you installed, whenever
they are needed, and **they are not kept in git at all**. The template's `.gitignore` already says so:

```
ana@dev:~/planner-native$ grep -n -B1 "^/android" .gitignore
40-/ios
41:/android
```

What replaces editing the native files is configuration. **`app.json` describes the app**, and each
package that needs something in the native projects brings a **config plugin**, a small program that
makes that change when they are generated, as `expo-router` did in lesson 8.

## Who the app is

`npx expo prebuild` is the command that generates them. Run it on the project as it stands and it
invents an identity, because `app.json` names none:

```
ana@dev:~/planner-native$ npx expo prebuild --platform android --no-install
Skipping Android package name reservation validation in offline-mode.
› Android package name: com.anonymous.plannernative
- Creating native directory (./android)
✔ Created native directory
- Updating package.json
✔ Updated package.json
- Running prebuild
» android: userInterfaceStyle: Install expo-system-ui in your project to enable this feature.
- Running prebuild
✔ Finished prebuild
ana@dev:~/planner-native$ grep applicationId android/app/build.gradle
        applicationId 'com.anonymous.plannernative'
```

The first line is the recording machine running Expo offline again, which skipped a check that the
name is free. **`com.anonymous.plannernative`** is a placeholder, and it is the same kind of decision as Capacitor's
`appId` in lesson 2: the app's identity in both stores, chosen once. Remove what was generated, and give
the app its identity in `app.json`, under `android.package` and `ios.bundleIdentifier`, the planner's
own one from lesson 2; the version-control state goes back to where it was:

```
ana@dev:~/planner-native$ rm -rf android && git checkout app.json package.json
Updated 2 paths from the index
ana@dev:~/planner-native$ grep -E "bundleIdentifier|\"package\"" app.json
      "bundleIdentifier": "com.example.studyplanner"
      "package": "com.example.studyplanner"
```

And generate again:

```
ana@dev:~/planner-native$ npx expo prebuild --platform android --no-install
- Creating native directory (./android)
✔ Created native directory
- Updating package.json
✔ Updated package.json
- Running prebuild
» android: userInterfaceStyle: Install expo-system-ui in your project to enable this feature.
- Running prebuild
✔ Finished prebuild
ana@dev:~/planner-native$ ls android
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle
ana@dev:~/planner-native$ grep applicationId android/app/build.gradle
        applicationId 'com.example.studyplanner'
ana@dev:~/planner-native$ git status --short
 M app.json
 M package.json
```

**`android/` is a complete Android project now**, with the identity `app.json` gave it, and the line
from Expo about `expo-system-ui` is a config plugin telling you that one setting in `app.json` needs a
package to take effect. On a Mac, `--platform ios` would write `ios/` the same way.

## Generated, so deleted

```
ana@dev:~/planner-native$ rm -rf android
ana@dev:~/planner-native$ git status --short
 M app.json
 M package.json
```

What `git status` shows is all that changed in the repository: `app.json`, with the identity, and
`package.json`, where `prebuild` changed the `android` and `ios` scripts to build the generated projects
on this computer. `android/` itself was never in git. **Delete it and nothing is lost**: the next
`prebuild` writes it again, from the same inputs. That is
the whole point, and the whole cost. An upgrade of Expo is an upgrade of `package.json` and a new
`prebuild`, with no native merge, which is where Capacitor apps spend their upgrade days. But a change
made by hand inside `android/` lasts until the next generation, so **a native change has to be a config
plugin**, written in JavaScript, which is more work than editing a file the first time and less every
time after.
