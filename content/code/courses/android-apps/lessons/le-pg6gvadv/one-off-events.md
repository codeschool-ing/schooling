---
title: Things that happen once
version: 1
---

**A snackbar saying "Added 45 min" is not state.** State is what is true now: the list, the total,
the draft. The snackbar reports that something happened, once, and after it is shown nothing about
the screen should remember it. Put it in `WeekUiState` as `message: String?` and the trouble starts
at the first rotation: the new screen reads the state, finds the message, and shows it again.

The planner sends it through a `Channel` instead:

```kotlin
private val _events = Channel<WeekEvent>(Channel.BUFFERED)
val events: Flow<WeekEvent> = _events.receiveAsFlow()
```

A channel delivers each element to **one** receiver and then it is gone, which is exactly "once".
Three properties make it suit a screen:

- **It waits for a receiver.** `Channel.BUFFERED` keeps up to 64 elements, so an event sent while the
  screen is rotating, with no collector for a moment, is delivered when the new screen's
  `LaunchedEffect` starts collecting. A `MutableSharedFlow` with no replay would drop it.
- **It is consumed.** The new screen after a rotation does not receive an event the old one already
  took.
- **`receiveAsFlow()` lets the screen collect it like any flow**, in the `LaunchedEffect` of section
  05.

## The other school of thought

Google's architecture guide for Android argues the opposite: that every event a ViewModel produces
should become state, a `userMessage` field in the UI state, and that the screen should call the
ViewModel back once it has shown it, so that the ViewModel clears the field. The argument is that
state can be tested by reading `state.value`, survives the process in a `SavedStateHandle` if it has
to, and cannot be lost between a send and a receive.

Both work, and they fail differently. A message in the state needs the screen to report "shown",
and forgetting that call shows it at every rotation. A channel needs no acknowledgement and can, in
a narrow case, lose an event: if the collector is cancelled after receiving it and before showing
it. **This course uses the channel for messages that are only information**, such as "Added 45 min",
where losing one costs nothing, and would put anything the student must see, an error that stops a
save for instance, into the state.
