---
title: Config plugins: native changes written as code
version: 1
---

**A config plugin is a JavaScript function that prebuild runs while it writes the native projects.**
It receives the configuration and a handle on each native file being written, the Android manifest,
`Info.plist`, the Gradle files, and changes them. Libraries ship plugins for their own setup; you
write one when your app needs a native change that `app.json` has no field for.

The planner will need one small fact on both platforms: **which day its week starts on**. A native
widget or notification written in Kotlin or Swift could read it from the app's own configuration. On
Android that is a `<meta-data>` entry in the manifest; on iOS, a key in `Info.plist`. Here is a
plugin that writes both. Save it in the project as `plugins/with-week-start.js`:

```schooling-example
{"language": "javascript", "file": "plugins/with-week-start.js", "parts": [{"code": "// plugins/with-week-start.js: write the planner's first day of the week into both native projects.\nconst { withAndroidManifest, withInfoPlist, AndroidConfig } = require(\"expo/config-plugins\");\n", "note": "The helpers come from `expo/config-plugins`, which the `expo` package already contains. A plugin runs in Node.js during prebuild, so it is CommonJS and `require`, not the app's TypeScript."}, {"code": "module.exports = function withWeekStart(config, { day = \"monday\" } = {}) {", "note": "A plugin takes the configuration and its own options, from the pair in `app.json`, and returns the configuration. The default makes the options optional."}, {"code": "  config = withAndroidManifest(config, (c) => {\n    const app = AndroidConfig.Manifest.getMainApplicationOrThrow(c.modResults);\n    AndroidConfig.Manifest.addMetaDataItemToMainApplication(app, \"planner.WEEK_STARTS\", day);\n    return c;\n  });", "note": "The Android half. `withAndroidManifest` hands over the manifest already parsed, as `c.modResults`; the two `AndroidConfig` functions find the `<application>` element and add a `<meta-data>` to it, replacing an earlier one of the same name."}, {"code": "  return withInfoPlist(config, (c) => {\n    c.modResults.PlannerWeekStarts = day;\n    return c;\n  });\n};", "note": "The iOS half. `Info.plist` arrives as a plain object, so a key is an assignment. Every callback returns what it was given, changed: that is how the next plugin receives it."}]}
```

## Using it

A plugin is named in `app.json`, in a list called `"plugins"` inside `"expo"`. Each entry is the
plugin's path or package name, or a pair of the name and its options. Add this at the end of the
`"expo"` object:

```json
"plugins": [["./plugins/with-week-start.js", { "day": "monday" }]]
```

Then generate the projects again and look for what the plugin wrote:

```
ana@dev:~/try-expo$ grep -A7 "\"plugins\"" app.json
    "plugins": [
      [
        "./plugins/with-week-start.js",
        {
          "day": "monday"
        }
      ]
    ]
ana@dev:~/try-expo$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ grep WEEK android/app/src/main/AndroidManifest.xml
    <meta-data android:name="planner.WEEK_STARTS" android:value="monday"/>
ana@dev:~/try-expo$ grep -A1 PlannerWeekStarts ios/tryexpo/Info.plist
    <key>PlannerWeekStarts</key>
    <string>monday</string>
```

**Both native files carry the value, and neither was edited by hand.** Delete the folders, change
`"monday"` to `"sunday"`, run prebuild, and both change together. That is the guarantee the bare
project could not give: the two platforms cannot disagree, because one function writes both.

## Mods, and why they are ordered

Each `with…` helper registers a **mod**, a change to one native file. Prebuild collects every mod of
every plugin and applies them file by file, in the order the plugins are listed, so two plugins that
touch the manifest see each other's changes rather than overwriting them. A plugin that edits text
with a regular expression instead of using the parsed file is the fragile kind: it works until the
template changes the line it matched. **Prefer the helpers**, which work on the parsed XML and plist,
and the `AndroidConfig` and `IOSConfig` functions that already know where a meta-data entry or a
permission goes.

## Where libraries use them

You will see plugins most often without writing any. `npx expo install expo-camera` adds the camera
library, and its plugin adds the camera permission to the manifest and the text iOS shows when it
asks. In lesson 13 you set that text through the plugin's options, and the plugin puts it in
`Info.plist` and the Android strings where each platform expects it.

A library with native code and no plugin is the case to watch for. It works in a bare project, where
you paste its setup lines by hand, and in an Expo project you write the plugin that pastes them. That
is rarely more than the twenty lines above.
