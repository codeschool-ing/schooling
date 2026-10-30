---
title: Collecting only while the screen can be seen
version: 1
---

**A flow collected by a screen nobody can see is work for nobody.** When the student presses the
home button, the activity stops: it still exists, and nothing of it is on screen. A collector that
keeps running then keeps the store busy, and with lesson 13's network or lesson 17's images it keeps
the radio and the battery busy too. `collectAsStateWithLifecycle()` collects only while the lifecycle
is at least `STARTED`, and stops when it drops below.

The screen is lesson 10's, with a `Scaffold` around it for section 05's snackbar, a loading state, and
a total the student can tap:

```kotlin
// app/src/main/java/com/example/planner/ui/WeekScreen.kt
package com.example.planner.ui

import androidx.compose.foundation.clickable
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.planner.R
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun WeekScreen(
    state: WeekUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggleDone: (Long) -> Unit,
    onTotalClick: () -> Unit,
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
            modifier = Modifier.clickable(onClick = onTotalClick),
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
fun WeekRoute(viewModel: WeekViewModel = viewModel(factory = WeekViewModel.Factory)) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val added = stringResource(R.string.added)
    val inHours = stringResource(R.string.in_hours, state.totalMinutes / 60, state.totalMinutes % 60)

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
            onAdd = { viewModel.onAdd(LocalDate.now()) },
            onToggleDone = viewModel::onToggleDone,
            onTotalClick = { scope.launch { snackbar.showSnackbar(inHours) } },
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
    <string name="in_hours">That is %1$d h %2$d min</string>
    <string name="session_row">%1$s · %2$d min</string>
</resources>
```

```kotlin
// app/src/main/java/com/example/planner/MainActivity.kt
package com.example.planner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import com.example.planner.ui.WeekRoute

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                WeekRoute()
            }
        }
    }
}
```

## Measuring who is listening

`InMemorySessionStore` exposes how many collectors its flow has. This test opens the activity,
stops it the way the home button does, waits, and starts it again, printing that number at each
step. Robolectric's main looper is paused, so `idle()` runs whatever is ready and `idleFor` moves
the clock forward:

```kotlin
// app/src/test/java/com/example/planner/SubscriptionTest.kt
package com.example.planner

import android.os.Looper
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import com.example.planner.data.Stores
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.Duration

@RunWith(RobolectricTestRunner::class)
class SubscriptionTest {
    @Test fun collectionFollowsTheLifecycle() {
        val subscribers = Stores.sessions.subscribers
        val looper = shadowOf(Looper.getMainLooper())
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            looper.idle()
            println("started:              ${subscribers.value}")
            scenario.moveToState(Lifecycle.State.CREATED)
            looper.idle()
            println("stopped, at once:     ${subscribers.value}")
            looper.idleFor(Duration.ofSeconds(4))
            println("stopped, 4 s later:   ${subscribers.value}")
            looper.idleFor(Duration.ofSeconds(2))
            println("stopped, 6 s later:   ${subscribers.value}")
            scenario.moveToState(Lifecycle.State.RESUMED)
            looper.idle()
            println("started again:        ${subscribers.value}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*SubscriptionTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
    started:              1
    stopped, at once:     1
    stopped, 4 s later:   1
    stopped, 6 s later:   0
    started again:        1
SubscriptionTest > collectionFollowsTheLifecycle PASSED
BUILD SUCCESSFUL in 10s
30 actionable tasks: 1 executed, 29 up-to-date
```

**One collector while the screen is visible, none five seconds after it stops.** The moment the
activity stopped, `collectAsStateWithLifecycle` stopped collecting `state`; but `state` is shared by
`stateIn`, and `WhileSubscribed(5_000)` kept the store's flow running for its grace period. Four
seconds in it still had its one collector; six seconds in it had none. Started again, the screen
collected again and the store had its collector back.

That is the two mechanisms doing different jobs. `collectAsStateWithLifecycle` decides **when the
screen listens**: from `STARTED` and above, which a plain `collectAsState()` does not, since it
collects for as long as the composable is in the composition, stopped activity or not.
`WhileSubscribed` decides **how long the expensive part keeps running** once nobody listens, which
is what lets a rotation pass without restarting it.
