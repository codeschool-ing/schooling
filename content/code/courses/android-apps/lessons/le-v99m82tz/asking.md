---
title: Asking from a composable
version: 1
---

**A permission request is an activity result**: the app launches the system's dialog and receives an
answer later, and Compose wraps that in `rememberLauncherForActivityResult`. The launcher is created
during composition, survives recomposition, and calls its lambda with `true` or `false` when the
student answers.

Start from lesson 1's project. The build file is lesson 1's with a `testLogging` block added, so
that the tests' printed lines appear as they do here; the permission APIs are in `androidx.core` and
`androidx.activity`, which the project already has:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

The manifest declares the permission, which lesson 19 section 05 showed is necessary before it can
be asked for at all:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

And the words the card uses, all of this lesson's:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="reminders_ask">Get a reminder on days with a session planned.</string>
    <string name="reminders_ask_button">Turn on reminders</string>
    <string name="reminders_explain">Reminders need permission to show a notification. The planner sends at most one a day, and never anything else.</string>
    <string name="reminders_explain_button">Allow notifications</string>
    <string name="reminders_settings">Notifications are off for the planner. You can turn them on in its settings.</string>
    <string name="reminders_settings_button">Open settings</string>
    <string name="reminders_on">Reminders are on.</string>
</resources>
```

## The composable that asks

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/RemindersSetting.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/ui/RemindersSetting.kt\npackage com.example.planner.ui\n\nimport android.Manifest\nimport android.content.Context\nimport android.content.Intent\nimport android.content.pm.PackageManager\nimport android.os.Build\nimport android.provider.Settings\nimport androidx.activity.compose.LocalActivity\nimport androidx.activity.compose.rememberLauncherForActivityResult\nimport androidx.activity.result.contract.ActivityResultContracts\nimport androidx.compose.runtime.Composable\nimport androidx.compose.runtime.getValue\nimport androidx.compose.runtime.mutableIntStateOf\nimport androidx.compose.runtime.remember\nimport androidx.compose.runtime.setValue\nimport androidx.compose.ui.platform.LocalContext\nimport androidx.core.app.ActivityCompat\nimport androidx.core.content.ContextCompat\n"}, {"code": "private const val PERMISSION = Manifest.permission.POST_NOTIFICATIONS\n", "note": "The permission's name, once. `Manifest.permission` holds the strings Android defines."}, {"code": "@Composable\nfun RemindersSetting() {\n    val context = LocalContext.current\n    val activity = LocalActivity.current ?: return\n    val prefs = remember { context.getSharedPreferences(\"permissions\", Context.MODE_PRIVATE) }\n    var answers by remember { mutableIntStateOf(0) }\n", "note": "`LocalActivity` is the activity hosting this composition; `shouldShowRequestPermissionRationale` needs it. The preferences file holds one flag: whether the app has ever asked."}, {"code": "    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {\n        prefs.edit().putBoolean(PERMISSION, true).apply()\n        answers++\n    }\n", "note": "**The launcher.** `RequestPermission` is the contract for one permission; the lambda runs when the student answers, with `true` or `false`. It records that the app asked, and bumps a counter so that the offer below is worked out again."}, {"code": "    val offer = remember(answers) {\n        offerFor(\n            sdk = Build.VERSION.SDK_INT,\n            granted = ContextCompat.checkSelfPermission(context, PERMISSION) ==\n                PackageManager.PERMISSION_GRANTED,\n            showRationale = ActivityCompat.shouldShowRequestPermissionRationale(activity, PERMISSION),\n            askedBefore = prefs.getBoolean(PERMISSION, false),\n        )\n    }\n", "note": "**Every answer Android can give, read fresh**: the phone's version, whether the permission is held, whether Android advises an explanation, and the app's own memory of asking. Section 04's function turns them into one decision."}, {"code": "    ReminderCard(\n        offer = offer,\n        onAsk = { launcher.launch(PERMISSION) },\n        onOpenSettings = {\n            context.startActivity(\n                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)\n                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),\n            )\n        },\n    )\n}", "note": "The card of section 05 does the drawing. Asking is `launch`; settings is an intent to the app's notification page, which Android has had since 8.0, this project's `minSdk`."}]}
```

Two things in that function are not about Compose and matter more than the rest. **The app has to
remember that it asked**, because Android does not tell it: the `SharedPreferences` flag is what
section 04 needs to tell "never asked" from "refused twice". And **the answer the launcher delivers
is not the whole state**: after a refusal, `shouldShowRequestPermissionRationale` may have changed,
so the function asks Android again rather than trusting the boolean alone.

The `answers` counter is the plainest way to say "recompute after every answer". A screen that
the student can leave and come back to should also recompute when it resumes, because the student
may have changed the permission in Settings meanwhile; lesson 11's lifecycle-aware collection is the
tool for that, and the planner's screen in a real app would use it.
