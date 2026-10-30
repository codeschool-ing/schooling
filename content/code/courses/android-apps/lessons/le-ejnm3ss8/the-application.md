---
title: The application class, and the initialiser you switch off
version: 1
---

**Something has to give WorkManager its factory before the first worker is built**, and in an app
that is the `Application` class: the one object Android creates when the process starts, before any
activity. Lesson 1's project has none, because nothing needed one. Now something does:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager
import com.example.planner.data.Uploader
import com.example.planner.work.PlannerWorkerFactory
import com.example.planner.work.scheduleSync

class PlannerApp : Application(), Configuration.Provider {

    // Lesson 16's repository sends the sessions; until then nothing is sent.
    private val uploader = Uploader { 0 }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(PlannerWorkerFactory(uploader))
            .build()

    override fun onCreate() {
        super.onCreate()
        scheduleSync(WorkManager.getInstance(this))
    }
}
```

`Configuration.Provider` is WorkManager's way of asking the application for its configuration. The
first call to `WorkManager.getInstance` finds it there and builds itself with the factory. And
`onCreate` schedules the periodic sync on every start, which section 04's `KEEP` makes harmless.

## The manifest: name the class, and remove the default

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:name=".PlannerApp"
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

        <provider
            android:name="androidx.startup.InitializationProvider"
            android:authorities="${applicationId}.androidx-startup"
            tools:node="merge">
            <meta-data
                android:name="androidx.work.WorkManagerInitializer"
                android:value="androidx.startup"
                tools:node="remove" />
        </provider>
    </application>

</manifest>
```

`android:name=".PlannerApp"` is what makes Android create your class rather than the plain
`Application`. The `<provider>` block is the part people forget. WorkManager's own manifest, merged
into yours as lesson 1 section 07 showed, registers an **initialiser** that sets WorkManager up with a
default configuration as the process starts, before your `Application` has a say. Leave it there and
your factory is never used: the default one tries to build `SyncWorker` with two parameters and
fails. `tools:node="remove"` is an instruction to the manifest merger, not to the phone: drop that
one entry from whatever the libraries contributed.

## What the merger made of it

Build, and look at what the merger produced:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E -A1 "Warning:|^BUILD"
BUILD SUCCESSFUL in 24s
36 actionable tasks: 22 executed, 14 up-to-date
ana@vm:~/planner$ grep -c WorkManagerInitializer app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
0
ana@vm:~/planner$ find ~/.gradle/caches -path "*work-runtime-2.12.0*" -name AndroidManifest.xml -exec grep -c WorkManagerInitializer {} \;
1
ana@vm:~/planner$ grep -o "uses-permission android:name=\"[^\"]*\"" app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
uses-permission android:name="android.permission.WAKE_LOCK"
uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"
uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"
uses-permission android:name="android.permission.FOREGROUND_SERVICE"
uses-permission android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
```

The build says nothing about the removal, so count. **The library's own manifest, in Gradle's
cache, declares the initialiser once, and the merged manifest has none of it**: the merger dropped
the entry, and WorkManager will wait for `PlannerApp` to configure it.

The permissions are the other thing to read, as lesson 1 asked whenever a library arrives. The
last one is lesson 1's, from `androidx.core`; you wrote none of the other four. `WAKE_LOCK` keeps the processor awake while a worker runs, `ACCESS_NETWORK_STATE`
lets WorkManager check the network constraint, `RECEIVE_BOOT_COMPLETED` is how it puts its jobs back
after a reboot, and `FOREGROUND_SERVICE` is for long work shown with a notification. None of them
asks the student anything: all four are granted at install, which lesson 20 explains.
