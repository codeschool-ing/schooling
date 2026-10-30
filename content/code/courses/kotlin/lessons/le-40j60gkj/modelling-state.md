---
title: Modelling a screen's state
version: 1
---

The week screen of the planner is, at any moment, loading its sessions, showing them, or showing an
error. The tempting model is one class with a field for each thing the screen might need:

```kotlin
data class WeekScreen(
    val loading: Boolean,
    val sessions: List<Int>?,
    val error: String?,
)
```

Three fields with two meaningful states each make eight combinations, and **five of them are
nonsense**: loading with an error, sessions and an error at once, nothing at all. Nothing stops the
code from building one, and every screen has to decide what to draw for each. That is how an app ends
up with a spinner turning over an error message.

The sealed version allows exactly the three that exist:

```kotlin
// WeekState.kt
sealed interface WeekState {
    data object Loading : WeekState
    data class Loaded(val sessions: List<Int>) : WeekState
    data class Failed(val message: String) : WeekState
}

fun render(state: WeekState): String = when (state) {
    WeekState.Loading -> "loading…"
    is WeekState.Loaded ->
        if (state.sessions.isEmpty()) "no sessions yet"
        else "${state.sessions.size} sessions, ${state.sessions.sum()} min"
    is WeekState.Failed -> "could not load the week: ${state.message}"
}

fun main() {
    val states = listOf(
        WeekState.Loading,
        WeekState.Loaded(emptyList()),
        WeekState.Loaded(listOf(45, 30, 60)),
        WeekState.Failed("the file is missing"),
    )
    states.forEach { println(render(it)) }
}
```

```
ana@vm:~/kt/l09$ kotlinc WeekState.kt -include-runtime -d weekstate.jar && java -jar weekstate.jar
loading…
no sessions yet
3 sessions, 135 min
could not load the week: the file is missing
```

`data object Loading` declares a single object rather than a class, because a loading state has no
data and there is only ever one of it; lesson 10 is about objects. Its branch has no `is`, because it
compares with that one object.

**Impossible states are now impossible to write.** A `Loaded` without sessions does not compile, a
`Failed` has a message by construction, and the empty week is a `Loaded` with an empty list, a real
state the screen has to draw, rather than a `null` that means two things. This is the shape every
screen in `android-apps` uses: lesson 17 of this course holds a `WeekState` in a `StateFlow`, and a
Compose screen there is a `when` over it, exactly like `render`.
