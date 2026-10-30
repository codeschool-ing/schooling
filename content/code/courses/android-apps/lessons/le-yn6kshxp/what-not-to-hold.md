---
title: What a ViewModel must never hold
version: 1
---

**A ViewModel outlives the activity, so it must not keep a reference to the activity.** That follows
from section 04 directly, and it is still the most common mistake made with one. The usual route
there is innocent: the ViewModel wants to format a string, strings live in resources, resources need
a `Context`, and the nearest `Context` is the activity that created it.

```kotlin
// app/src/main/java/com/example/planner/ui/LeakyViewModel.kt
package com.example.planner.ui

import android.content.Context
import androidx.lifecycle.ViewModel

class LeakyViewModel(private val context: Context) : ViewModel() {
    fun greeting(): String = context.getString(com.example.planner.R.string.app_name)
}
```

It compiles and it works, until the phone turns. Then the activity is destroyed, a new one is built,
and this ViewModel, kept alive on purpose by the `ViewModelStore`, still points at the old one. The
old activity cannot be collected, and neither can its window, its views and everything they hold:
**a whole screen kept in memory for nothing, once per rotation**. Android's own linter knows the
pattern:

```
ana@vm:~/planner$ ./gradlew --console=plain lintDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 28s
ana@vm:~/planner$ grep -A2 "\[StaticFieldLeak\]" app/build/reports/lint-results-debug.txt
/home/ana/planner/app/src/main/java/com/example/planner/ui/LeakyViewModel.kt:7: Warning: This field leaks a context object [StaticFieldLeak]
class LeakyViewModel(private val context: Context) : ViewModel() {
                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

The build still succeeds: lint reports a warning and does not fail on it unless the build file says
`lint { warningsAsErrors = true }`. `StaticFieldLeak` is the name of the check, and its explanation talks about static fields because
that was the first way people leaked a context; a field of an object that outlives the activity is
the same leak.

## Where the `Context` goes instead

Look back at `WeekViewModel`. It never formats a sentence: `WeekUiState` carries `totalMinutes`,
`doneCount` and the list, and `WeekScreen` turns them into words with
`stringResource(R.string.week_total, …)`. **The ViewModel produces values and the screen produces
text**, which also means the sentence follows the phone's language without the ViewModel knowing
there are languages. Lesson 1 section 07 is where that choice is made.

Three more things to keep out, for the same reason or a close one:

| keep out of a ViewModel | why |
|---|---|
| an `Activity`, a `View`, a `Fragment` | each lives shorter than the ViewModel, so each is a leak |
| a `NavController` or anything else from composition | it belongs to one composition; navigating is something the screen does when an event asks for it |
| a lambda that captures any of the above | the capture is a hidden reference, the same leak with no field to read |

When a ViewModel genuinely needs something from the platform, the answer from lesson 12 on is to ask
for that one thing through its constructor, a `SessionStore` rather than a `Context`. The
`Application` object lives as long as the process, so it does not leak, and `AndroidViewModel` is a
base class that receives it. It is still a `Context` in a class that section 07 wants to test with
no Android, so this course does not use it.
