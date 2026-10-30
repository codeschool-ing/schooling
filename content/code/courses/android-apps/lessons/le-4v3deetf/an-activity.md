---
title: An activity is a window the system lends you
version: 1
---

**You never create an activity.** The system does. When somebody taps the planner's icon, Android
reads the manifest, finds the activity whose `<intent-filter>` says `LAUNCHER`, makes an instance of
that class with its own constructor, and then calls methods on it as things happen to the screen.
Your code runs inside those calls and nowhere else. An activity is a guest of the system's, and the
calls are how the system tells it what is going on.

The calls are called **lifecycle callbacks**: `onCreate`, `onStart`, `onResume`, `onPause`,
`onStop` and `onDestroy`, plus `onSaveInstanceState`, which section 04 needs. To watch them,
lesson 1's `MainActivity` gets one log line in each:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/MainActivity.kt", "parts": [
{"code": "package com.example.planner\n\nimport android.os.Bundle\nimport android.util.Log\nimport androidx.activity.ComponentActivity\nimport androidx.activity.compose.setContent\nimport androidx.compose.material3.MaterialTheme\nimport androidx.compose.material3.Surface\nimport androidx.compose.material3.Text\nimport androidx.compose.ui.res.stringResource\n\nprivate const val TAG = \"Lifecycle\"", "note": "`Log.d` writes to the system log, which `adb logcat` reads on a phone. The tag is the label to filter by."},
{"code": "object ProcessWide {\n    var created = 0\n}", "note": "A Kotlin `object` lives as long as the process does. It counts how many activities this process has created, which section 05 needs."},
{"code": "class MainActivity : ComponentActivity() {\n    override fun onCreate(savedInstanceState: Bundle?) {\n        super.onCreate(savedInstanceState)\n        ProcessWide.created++\n        Log.d(TAG, \"onCreate: instance ${ProcessWide.created} in this process, saved state: ${savedInstanceState != null}\")\n        setContent {\n            MaterialTheme {\n                Surface {\n                    Text(stringResource(R.string.welcome))\n                }\n            }\n        }\n    }", "note": "`onCreate` runs once per instance. `savedInstanceState` is null on a fresh start, and is a `Bundle` when the system is rebuilding an activity it destroyed itself. Every callback has to call `super`, or the framework throws `SuperNotCalledException`."},
{"code": "    override fun onStart() { super.onStart(); Log.d(TAG, \"onStart\") }\n    override fun onResume() { super.onResume(); Log.d(TAG, \"onResume\") }\n    override fun onPause() { Log.d(TAG, \"onPause\"); super.onPause() }\n    override fun onStop() { Log.d(TAG, \"onStop\"); super.onStop() }", "note": "Four calls in two pairs: visible and invisible, in front and not. The ones going down log before `super`, so the log reads in the order things happen."},
{"code": "    override fun onSaveInstanceState(outState: Bundle) {\n        super.onSaveInstanceState(outState)\n        Log.d(TAG, \"onSaveInstanceState\")\n    }\n\n    override fun onDestroy() {\n        Log.d(TAG, \"onDestroy: finishing $isFinishing, configuration change $isChangingConfigurations\")\n        super.onDestroy()\n    }\n}", "note": "`isFinishing` says the activity is going away for good; `isChangingConfigurations` says the system will make a new one straight away. Section 04 shows the second."}
]}
```

**`ComponentActivity` is the class to extend.** Android's own `Activity` is the base of everything,
and `androidx.activity` adds what modern code needs on top: a `Lifecycle` object other code can
observe, the back button as a callback, `setContent` for Compose, and the saved-state machinery
lesson 10's `ViewModel` relies on. Older projects extend `AppCompatActivity`, which adds the
pre-Compose toolbar and theming on top of the same class; a Compose app does not need it.

## Three things an activity is not

**It is not the app.** An app is a process, and an activity is one object inside it; an app can
have several activities, or none on screen while it still runs. Section 05 is about the process.

**It is not something you call.** `MainActivity()` written in your own code compiles, and gives
you an object the system knows nothing about: no window, no lifecycle, and a crash the first time
it touches either. Starting an activity is a request to the system, section 07's subject.

**It is not where the data lives.** The system destroys and rebuilds activities when it likes,
section 04 shows how often, and anything kept only in an activity's fields goes with it. Lesson 10
moves the planner's data out.
