---
title: A composable is a function that describes, and returns nothing
version: 1
---

**A composable is a Kotlin function marked `@Composable` that describes part of the screen.** It
does not return a view, a widget or anything else; its return type is `Unit`. What it does instead
is **emit**: each composable it calls adds a node to a tree Compose keeps, and Compose draws that
tree. The function says what the screen should look like for the values it was given, and Compose
works out what to change on screen.

The old picture, from the `View` system lesson 2 mentioned, is of objects you create, keep in a
field and later tell to change: `textView.setText("95 min")`. There is nothing to keep in Compose.
To show different text you call the function again with a different value, and that is the whole
mechanism; lesson 5 is about when Compose does that calling.

The planner's first composable shows one course and the minutes studied in it this week. It needs
the model, which lives in its own file:

```kotlin
// app/src/main/java/com/example/planner/data/Course.kt
package com.example.planner.data

data class Course(val id: String, val name: String)

val sampleCourses = listOf(
    Course("kotlin", "Kotlin"),
    Course("android", "Android Apps"),
    Course("sql", "SQL Databases"),
)
```

And the composable, which section 04 shows whole, with its imports and a preview:

```kotlin
@Composable
fun CourseRow(course: Course, minutesThisWeek: Int) {
    Column {
        Text(course.name, style = MaterialTheme.typography.titleMedium)
        Text(
            stringResource(R.string.minutes_this_week, minutesThisWeek),
            style = MaterialTheme.typography.bodySmall,
        )
    }
}
```

Three conventions are visible in five lines. **A composable that emits is named like a class**, in
PascalCase, because it reads as a noun: `CourseRow`, `Column`, `Text`. A composable that *returns*
a value instead of emitting, like `stringResource` here or lesson 4's `remember`, is named like an
ordinary function. And the text comes from `strings.xml`, with `%1$d` where the number goes, so that
lesson 1's `values-pt` can translate it.

## The annotation is a contract the compiler holds

`@Composable` is not decoration. The Compose compiler plugin, `kotlin.compose` in the build file,
rewrites every function that carries it to take a hidden extra parameter, the **composer**, which is
how the function reaches the tree it emits into. A plain function has no composer to pass on, so
calling a composable from one cannot work, and the compiler says so:

```kotlin
// app/src/main/java/com/example/planner/ui/Summary.kt
package com.example.planner.ui

import com.example.planner.data.Course

fun summary(course: Course): String {
    CourseRow(course, minutesThisWeek = 95)
    return course.name
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugKotlin 2>&1 | grep -E "^e:|^BUILD"
e: file:///home/ana/planner/app/src/main/java/com/example/planner/ui/Summary.kt:6:5 Functions which invoke @Composable functions must be marked with the @Composable annotation
e: file:///home/ana/planner/app/src/main/java/com/example/planner/ui/Summary.kt:7:5 @Composable invocations can only happen from the context of a @Composable function
BUILD FAILED in 6s
```

Both errors are the same rule seen from two sides: the function that calls a composable must be one
itself, and a composable may only be called from inside one. **The fix is never to add
`@Composable` to `summary`**: it returns a string and draws nothing, and making it a composable
would let it be called only while the screen is being composed. A function that computes something
stays a plain function, and the composable calls it. The file is deleted before going on.
