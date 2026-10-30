---
title: remember keeps a value in the composition
version: 1
---

**`remember { … }` runs its lambda the first time a composable reaches that line, and returns the
same result every time after.** Where does it keep it? In the composition, the tree lesson 3 drew,
in the node of the composable that called it. That has two consequences that explain most of what
`remember` does and does not do.

**Each call site gets its own value.** Two `RememberedCounter()`s side by side are two nodes, and
each has its own remembered state; clicking one does not move the other. That is the same reason
`CourseRow` appeared twice in lesson 3's tree.

**The value lives exactly as long as the node.** While the composable stays in the composition, the
value survives every recomposition. When the composable leaves, because an `if` stopped calling it
or the user navigated to another screen, the node is removed and the value with it. Come back and
`remember` runs its lambda again, from zero. And the composition itself belongs to the activity, so
when lesson 2's rotation destroys the activity, every remembered value goes, which is section 04.

## Keys: remembering again when an input changes

A remembered value can depend on a parameter. A screen showing one course might remember a
formatter, a sorted list or a draft built from that course, and must not keep the old one when it is
handed a different course. `remember` takes **keys** for that:

```kotlin
@Composable
fun CourseHeader(course: Course) {
    val initials = remember(course.id) { course.name.split(" ").map { it.first() }.joinToString("") }
    Text(initials)
}
```

That fragment illustrates the call and was not compiled here. With `course.id` as a key, the lambda
runs again whenever the id is different from last time, and is skipped otherwise. Without the key,
the header would show the first course's initials for every course afterwards, because `remember`
had no reason to run again.

**`remember` is a cache, not a store.** It saves work and keeps an object stable across runs, and
anything that must outlive the node has to live somewhere else. Section 04 shows the first place,
`rememberSaveable`; lesson 10 shows the second, a `ViewModel`.
