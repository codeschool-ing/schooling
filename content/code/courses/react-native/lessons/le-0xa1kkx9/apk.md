---
title: The module inside a real build
version: 1
---

**A test proves the rule; a build proves the module is wired.** The same debug build as lesson 3, for one
processor architecture to keep it quicker, compiles every Kotlin file of every module into the app, the
local one included:

```
ana@dev:~/planner/android$ ./gradlew :app:assembleDebug -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1
ana@dev:~/planner/android$ du -h app/build/outputs/apk/debug/app-debug.apk
91M	app/build/outputs/apk/debug/app-debug.apk
ana@dev:~/planner/android$ unzip -p app/build/outputs/apk/debug/app-debug.apk 'classes*.dex' | grep -a -o 'org/example/weekstart/[A-Za-z]*' | sort -u
org/example/weekstart/R
org/example/weekstart/WeekStartModule
org/example/weekstart/WeekStartModuleKt
```

The build took a few minutes, most of them in the C++ of the libraries from lessons 12 to 16, and the APK
has grown well past lesson 3's 64 MB with them. The last command reads the app's compiled Java bytecode, the
`classes*.dex` files inside the APK, and finds three classes from the module's package: `WeekStartModule`,
the module; `WeekStartModuleKt`, where Kotlin puts the top-level `firstWeekday` function; and `R`, the
resources class every Android library gets.

*That proves the module is compiled in and nothing more. Whether a phone running this APK answers 0 in
Brazil was not run: there is no emulator on the machine that recorded this course, which has no hardware
virtualisation, and no phone attached to it.*
