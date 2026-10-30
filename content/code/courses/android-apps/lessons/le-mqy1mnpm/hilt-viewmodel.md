---
title: A ViewModel Hilt builds
version: 1
---

**`@HiltViewModel` and an `@Inject` constructor replace lesson 11's hand-written factory.** The
ViewModel lists what it needs; Hilt finds each one in the graph, and gives it the
`SavedStateHandle` that belongs to this screen, which it treats as a binding of its own.

```kotlin
// app/src/main/java/com/example/planner/ui/WeekViewModel.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.planner.data.SessionStore
import com.example.planner.data.StudySession
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.Clock
import java.time.LocalDate
import javax.inject.Inject
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class WeekUiState(
    val sessions: List<StudySession> = emptyList(),
    val draftMinutes: String = "",
    val loading: Boolean = false,
) {
    val totalMinutes: Int get() = sessions.sumOf { it.minutes }
    val doneCount: Int get() = sessions.count { it.done }
    val canAdd: Boolean get() = draftMinutes.toIntOrNull() in 5..240
}

sealed interface WeekEvent {
    data class Added(val minutes: Int) : WeekEvent
}

@HiltViewModel
class WeekViewModel @Inject constructor(
    private val store: SessionStore,
    private val clock: Clock,
    private val saved: SavedStateHandle,
) : ViewModel() {
    private val draft: StateFlow<String> = saved.getStateFlow(DRAFT, "")

    val state: StateFlow<WeekUiState> =
        combine(store.sessions(), draft) { sessions, text ->
            WeekUiState(sessions = sessions, draftMinutes = text)
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), WeekUiState(loading = true))

    private val _events = Channel<WeekEvent>(Channel.BUFFERED)
    val events: Flow<WeekEvent> = _events.receiveAsFlow()
    private var nextId = 1L

    fun onDraftChange(text: String) {
        saved[DRAFT] = text
    }

    fun onAdd() {
        val minutes = draft.value.toIntOrNull() ?: return
        if (minutes !in 5..240) return
        saved[DRAFT] = ""
        viewModelScope.launch {
            store.add(StudySession(nextId++, "android", LocalDate.now(clock), minutes))
            _events.send(WeekEvent.Added(minutes))
        }
    }

    fun onToggleDone(id: Long) {
        viewModelScope.launch { store.toggleDone(id) }
    }

    private companion object {
        const val DRAFT = "draft"
    }
}
```

Compared with lesson 11, three lines changed meaning and one block disappeared. The constructor
gained `@Inject` and a `Clock`; `onAdd` no longer takes a date, because it asks the clock; and the
`companion object` with its `viewModelFactory` is gone, along with the `Stores` object it reached
into. **Nothing in this file says where the store comes from**, which is the point: the module of
section 03 decides, and a test decides differently.

The screen changes in one line. `hiltViewModel()` replaces `viewModel(factory = …)`, and finds the
factory Hilt generated:

```kotlin
// app/src/main/java/com/example/planner/ui/WeekScreen.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.planner.R

@Composable
fun WeekScreen(
    state: WeekUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggleDone: (Long) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (state.loading) {
            Text(stringResource(R.string.loading))
            return@Column
        }
        Text(
            stringResource(R.string.week_total, state.totalMinutes, state.doneCount, state.sessions.size),
            style = MaterialTheme.typography.titleMedium,
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(
                value = state.draftMinutes,
                onValueChange = onDraftChange,
                label = { Text(stringResource(R.string.minutes)) },
                modifier = Modifier.weight(1f),
            )
            Button(onClick = onAdd, enabled = state.canAdd, modifier = Modifier.padding(start = 8.dp)) {
                Text(stringResource(R.string.add))
            }
        }
        for (session in state.sessions) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(checked = session.done, onCheckedChange = { onToggleDone(session.id) })
                Text(stringResource(R.string.session_row, session.date.toString(), session.minutes))
            }
        }
    }
}

@Composable
fun WeekRoute(viewModel: WeekViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val added = stringResource(R.string.added)

    LaunchedEffect(viewModel) {
        viewModel.events.collect { event ->
            when (event) {
                is WeekEvent.Added -> snackbar.showSnackbar(added.format(event.minutes))
            }
        }
    }

    Scaffold(snackbarHost = { SnackbarHost(snackbar) }) { padding ->
        WeekScreen(
            state = state,
            onDraftChange = viewModel::onDraftChange,
            onAdd = viewModel::onAdd,
            onToggleDone = viewModel::onToggleDone,
            modifier = Modifier.padding(padding),
        )
    }
}
```

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="loading">Loading the week…</string>
    <string name="week_total">%1$d min this week, %2$d of %3$d done</string>
    <string name="minutes">Minutes</string>
    <string name="add">Add</string>
    <string name="added">Added %1$d min</string>
    <string name="session_row">%1$s · %2$d min</string>
</resources>
```

With every file in place, the app builds:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|^e: |error:"
BUILD SUCCESSFUL in 1m
41 actionable tasks: 41 executed
```

`hiltViewModel()` only works inside an activity marked `@AndroidEntryPoint`, which is why section 03
marked `MainActivity`. Called from an activity Hilt does not know, it fails at run time with a
message naming the missing annotation, one of the few Hilt mistakes the compiler cannot see.
