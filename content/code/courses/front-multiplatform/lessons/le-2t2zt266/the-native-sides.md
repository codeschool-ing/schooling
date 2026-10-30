---
title: The Android and iOS halves
version: 1
---

**Each native half is one class, and each method is a function the bridge calls with the JavaScript
call's arguments and a way to answer it.** Replace the generated plugin class on each side.

*Neither file was compiled for this course: building Kotlin for Android needs the Android SDK, and
Swift for iOS needs Xcode, and the recording machine had neither (lesson 3 says why). They follow
Capacitor's plugin guides for Android and iOS, and the Android and Apple interfaces they call are the
documented ones for keeping the screen on.*

## Android, in Kotlin

```kotlin
// android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt
package com.example.keepawake

import android.view.WindowManager
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "KeepAwake")
class KeepAwakePlugin : Plugin() {

    @PluginMethod
    fun keepAwake(call: PluginCall) {
        activity.runOnUiThread {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            call.resolve()
        }
    }

    @PluginMethod
    fun allowSleep(call: PluginCall) {
        activity.runOnUiThread {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            call.resolve()
        }
    }

    @PluginMethod
    fun isSupported(call: PluginCall) {
        call.resolve(JSObject().put("supported", true))
    }
}
```

- **`@CapacitorPlugin(name = "KeepAwake")`** registers the class under the name `src/index.ts` used.
  **`@PluginMethod`** exposes a method to JavaScript under its own name, so `keepAwake` here answers
  `KeepAwake.keepAwake()` there.
- **`call`** is the JavaScript call: its arguments come out of it with `call.getString(…)` and the like,
  and `call.resolve(…)` or `call.reject(…)` settles the `Promise` waiting on the other side. A method
  that never calls either leaves that `Promise` pending for ever, which is the classic bug of a first
  plugin.
- **`FLAG_KEEP_SCREEN_ON`** is a flag on the activity's window: while it is set, the screen stays on,
  and it stops applying when the activity leaves the screen. No permission is needed for it.
- **`runOnUiThread`**: the bridge calls plugin methods on a thread of its own, and Android only lets the
  main thread change a window.

## iOS, in Swift

```swift
// ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift
import Foundation
import UIKit
import Capacitor

@objc(KeepAwakePlugin)
public class KeepAwakePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "KeepAwakePlugin"
    public let jsName = "KeepAwake"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "keepAwake", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "allowSleep", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isSupported", returnType: CAPPluginReturnPromise)
    ]

    @objc func keepAwake(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
            call.resolve()
        }
    }

    @objc func allowSleep(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            call.resolve()
        }
    }

    @objc func isSupported(_ call: CAPPluginCall) {
        call.resolve(["supported": true])
    }
}
```

- **`jsName`** is the name again, and **`pluginMethods`** lists every method JavaScript may call. On
  iOS a method missing from that list is not reachable at all, which is the second classic bug.
- **`isIdleTimerDisabled`** is the switch iOS gives for the same thing: while it is `true`, the
  system's timer that dims and locks the screen does not run. Apple's documentation asks apps to set it
  only while it is needed, which is what `allowSleep` is for.
- **`DispatchQueue.main.async`** is iOS's form of `runOnUiThread`: interface changes happen on the main
  thread.

**Both sides answer `isSupported` with `true`**, because both systems have the feature on every version
Capacitor 8 supports. The web side is the only one that has to check.
