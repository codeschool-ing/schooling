---
title: Everything a composable shows arrives as a parameter
version: 1
---

**`CourseRow` knows nothing it was not given.** It does not look up the course, does not read a
database, does not keep the minutes anywhere; it receives a `Course` and an `Int` and describes them.
Call it with `Course("sql", "SQL Databases")` and `0`, and it describes that. A composable written
this way is called **stateless**, and it is the shape most of the planner's composables will have:
data flows in through parameters and the function turns it into a description of the screen.

That shape pays three times over:

- **It can be shown with any data.** A preview, section 04, calls it with a made-up course; a test,
  lesson 21, calls it with the awkward cases, a course called something very long, zero minutes,
  ten thousand minutes.
- **It can be reused.** The course list, the week's summary and a search result can all show
  `CourseRow`, each with its own data.
- **It cannot be wrong about where the data came from**, because it never fetches any. When lesson 15
  moves the courses into a database, `CourseRow` does not change.

The opposite shape, a composable that finds its own data, is tempting because the call site gets
shorter: `CourseRow("kotlin")` and the row does the rest. Every advantage in the list above is then
gone, and the row can only be previewed with a working database behind it.

## What a parameter list usually looks like

Compose's own components follow a pattern worth copying, and `Button` shows all of it at once:

```kotlin
@Composable
fun Button(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    // … colours, shape, padding …
    content: @Composable RowScope.() -> Unit,
)
```

That signature is abridged from Material 3's own and was not compiled here. Read it in four parts:

1. **What is required comes first**, without a default: `onClick`, what to do when pressed.
2. **`modifier: Modifier = Modifier`** is the first optional parameter, by convention, in every
   component that emits a layout. It is how the caller decides size, padding and position, which is
   lesson 6's subject.
3. **Everything else has a default**, so the simplest call is short and the full one is possible.
4. **A slot comes last**, a composable lambda, so that the caller's content can be written in braces
   after the call: `Button(onClick = { … }) { Text("Add") }`. Section 05 is about slots.

`onClick` is the other direction of data. Values come **in** as parameters; what the user does goes
**out** as a function the caller passed. `CourseRow` will grow an `onClick: () -> Unit` when the
list becomes something to tap, in lesson 8, and lesson 10 names the pattern: state down, events up.
