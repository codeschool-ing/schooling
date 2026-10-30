---
title: From the store's flow to the screen's state
version: 1
---

**The screen needs one `StateFlow` it can read at any moment; the store offers a `Flow` that
produces values only while somebody collects it.** Lesson 17 of `kotlin` named the difference: a
cold flow does nothing until collected, a hot `StateFlow` always has a current value. `stateIn` is
the bridge between them, and the arguments it takes are the decisions this section is about.

Here is the week's ViewModel rewritten around the store:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/WeekViewModel.kt", "parts": [{"code": "package com.example.planner.ui\n\nimport androidx.lifecycle.SavedStateHandle\nimport androidx.lifecycle.ViewModel\nimport androidx.lifecycle.createSavedStateHandle\nimport androidx.lifecycle.viewModelScope\nimport androidx.lifecycle.viewmodel.initializer\nimport androidx.lifecycle.viewmodel.viewModelFactory\nimport com.example.planner.data.SessionStore\nimport com.example.planner.data.Stores\nimport com.example.planner.data.StudySession\nimport kotlinx.coroutines.channels.Channel\nimport kotlinx.coroutines.flow.Flow\nimport kotlinx.coroutines.flow.SharingStarted\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.combine\nimport kotlinx.coroutines.flow.receiveAsFlow\nimport kotlinx.coroutines.flow.stateIn\nimport kotlinx.coroutines.launch\nimport java.time.LocalDate"}, {"code": "data class WeekUiState(\n    val sessions: List<StudySession> = emptyList(),\n    val draftMinutes: String = \"\",\n    val loading: Boolean = false,\n) {\n    val totalMinutes: Int get() = sessions.sumOf { it.minutes }\n    val doneCount: Int get() = sessions.count { it.done }\n    val canAdd: Boolean get() = draftMinutes.toIntOrNull() in 5..240\n}\n\nsealed interface WeekEvent {\n    data class Added(val minutes: Int) : WeekEvent\n}", "note": "Lesson 10's state, with one more field: `loading`, true until the first list arrives from the store. `WeekEvent` is section 06's subject."}, {"code": "class WeekViewModel(\n    private val store: SessionStore,\n    private val saved: SavedStateHandle,\n) : ViewModel() {\n    private val draft: StateFlow<String> = saved.getStateFlow(DRAFT, \"\")", "note": "The store comes in through the constructor. The draft is no longer copied into a field: `getStateFlow` turns the handle's key into a flow, so the handle is the only place it lives."}, {"code": "    val state: StateFlow<WeekUiState> =\n        combine(store.sessions(), draft) { sessions, text ->\n            WeekUiState(sessions = sessions, draftMinutes = text)\n        }.stateIn(\n            scope = viewModelScope,\n            started = SharingStarted.WhileSubscribed(5_000),\n            initialValue = WeekUiState(loading = true),\n        )", "note": "Two cold sources become one hot `StateFlow`. `combine` makes a new state whenever either changes; `stateIn` runs that in `viewModelScope`, starts when the screen collects, and stops five seconds after the last collector leaves."}, {"code": "    private val _events = Channel<WeekEvent>(Channel.BUFFERED)\n    val events: Flow<WeekEvent> = _events.receiveAsFlow()\n    private var nextId = 1L", "note": "A channel for things that happen once, read by exactly one collector. Section 06 explains why it is not part of the state."}, {"code": "    fun onDraftChange(text: String) {\n        saved[DRAFT] = text\n    }\n\n    fun onAdd(date: LocalDate) {\n        val minutes = draft.value.toIntOrNull() ?: return\n        if (minutes !in 5..240) return\n        saved[DRAFT] = \"\"\n        viewModelScope.launch {\n            store.add(StudySession(nextId++, \"android\", date, minutes))\n            _events.send(WeekEvent.Added(minutes))\n        }\n    }\n\n    fun onToggleDone(id: Long) {\n        viewModelScope.launch { store.toggleDone(id) }\n    }", "note": "The functions no longer touch the state. They write to the handle or to the store, and the new state arrives through `combine`, the same way a change made by anybody else would."}, {"code": "    companion object {\n        private const val DRAFT = \"draft\"\n\n        val Factory = viewModelFactory {\n            initializer { WeekViewModel(Stores.sessions, createSavedStateHandle()) }\n        }\n    }\n}", "note": "A ViewModel with constructor arguments needs a factory that knows how to build it. `createSavedStateHandle()` gives it the same handle lesson 10's default factory did. Lesson 12 replaces this hand-written factory with Hilt."}]}
```

## The three arguments of `stateIn`

**`scope = viewModelScope`** is where the upstream runs: the `combine` and the store's flow inside
it. Section 02 showed that scope ending with the ViewModel, so nothing here outlives the screen's
owner.

**`initialValue`** is what `state.value` holds before the first list arrives. A `StateFlow` must
always have a value, and the honest one here is "loading", which the screen draws as such. An empty
list would be a lie: it would say "no sessions" for the moment it takes to read them.

**`started = SharingStarted.WhileSubscribed(5_000)`** decides when the upstream runs. The table in
lesson 17 of `kotlin` compared the three choices; on Android the argument for this one is the
lifecycle:

| `started` | the store is collected | the cost |
|---|---|---|
| `Eagerly` | from the ViewModel's creation to its end | the screen in the background still reads the store, for nobody |
| `Lazily` | from the first collector to the ViewModel's end | the same, once somebody has looked |
| `WhileSubscribed(5_000)` | while the screen collects, and five seconds after it stops | a rotation is shorter than five seconds, so it does not restart; a screen left in the background stops after five |

**The five seconds are a rotation's worth of patience.** During a rotation the old screen stops
collecting and the new one starts again a moment later; without the grace period, the store's flow
would be torn down and set up again for every turn of the phone. Section 04 measures exactly this
on the planner.

## `combine`, and why the draft is in it

The state now has two sources, the sessions from the store and the draft from the handle, and
`combine` makes a new `WeekUiState` whenever either changes. That means **no function of the
ViewModel builds the state by hand any more**. `onAdd` writes the session to the store and the
cleared draft to the handle, and the new state arrives on its own, exactly as it would if another
part of the app had added the session. One path for every change is what makes lesson 16's
repository, where the network can also change the list, a small step from here.
