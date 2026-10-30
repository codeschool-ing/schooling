---
title: An identity before anything is built
version: 1
---

The first build stops before it compiles anything:

```
ana@dev:~/planner$ npx tauri build
        Info Looking up installed tauri packages to check mismatched versions...
You must change the bundle identifier in `tauri.conf.json identifier`. The default value `com.tauri.dev` is not allowed as it must be unique across applications.
       Error You must change the bundle identifier in `tauri.conf.json identifier`. The default value `com.tauri.dev` is not allowed as it must be unique across applications.
ana@dev:~/planner$ sed -i 's/"com.tauri.dev"/"com.example.studyplanner"/' src-tauri/tauri.conf.json
ana@dev:~/planner$ grep -E "productName|identifier|frontendDist|title" src-tauri/tauri.conf.json
  "productName": "planner",
  "identifier": "com.example.studyplanner",
    "frontendDist": "../dist",
        "title": "Study planner",
```

**Tauri refuses its own placeholder.** `com.tauri.dev` is the identifier the template writes, and like
Capacitor's `appId` of lesson 2 and Expo's `package` of lesson 9, an identifier is the app's identity. On macOS it names the bundle, on Windows the installer, and on every system it names the folder where the
app keeps its data. Giving it the planner's own one, `com.example.studyplanner`, the same as the phone
app's, is one `sed` on the configuration, and the other settings are what `tauri init` was told.

`productName` is `planner`, which names the packages lesson 13 builds; the window's title is `Study
planner`.
