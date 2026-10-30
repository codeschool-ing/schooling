---
title: Testing a ViewModel that runs coroutines
version: 1
---

**`viewModelScope` runs on `Dispatchers.Main`, and a plain JVM test has no main thread.** Call
`onAdd` in lesson 10's style of test and it fails before it starts, because there is no Android
looper behind `Main`. The coroutine test library's answer is to replace `Main` with a test
dispatcher for the length of the test, which is what `Dispatchers.setMain` does. Lesson 18 of
`kotlin` met `runTest` and virtual time; this is the same machinery pointed at a ViewModel.

```kotlin
// app/src/test/java/com/example/planner/ui/WeekViewModelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import com.example.planner.data.InMemorySessionStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class WeekViewModelTest {
    private val main = UnconfinedTestDispatcher()
    private val monday = LocalDate.of(2026, 10, 26)

    @Before fun mainIsATestDispatcher() = Dispatchers.setMain(main)
    @After fun mainIsRestored() = Dispatchers.resetMain()

    @Test fun withNobodyCollectingTheStateStaysLoading() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertTrue(vm.state.value.loading)
    }

    @Test fun withACollectorTheStateFollowsTheStore() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        backgroundScope.launch { vm.state.collect {} }
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(45, vm.state.value.totalMinutes)
        assertEquals("", vm.state.value.draftMinutes)
    }

    @Test fun addingSendsOneEvent() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(WeekEvent.Added(45), vm.events.first())
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
WeekViewModelTest > withACollectorTheStateFollowsTheStore PASSED
WeekViewModelTest > withNobodyCollectingTheStateStaysLoading PASSED
WeekViewModelTest > addingSendsOneEvent PASSED
BUILD SUCCESSFUL in 2s
30 actionable tasks: 1 executed, 29 up-to-date
```

The first test is the one that surprises people. **Nobody collects `state`, so `WhileSubscribed`
never starts the upstream**, and `state.value` stays at the initial value however many sessions are
added. That is `stateIn` working as section 03 described, and it is why the second test starts a
collector in `backgroundScope` first: a scope `runTest` cancels by itself when the test ends, so the
collector cannot keep the test waiting.

`UnconfinedTestDispatcher` runs each coroutine immediately, up to its first real suspension, which
keeps these tests in a straight line: `onAdd` returns after the store has been written. Section 02's
`CancelTest` used a `StandardTestDispatcher` instead, which runs nothing until the test advances the
clock, because there the point was to stop half-way.

The third test reads one event with `first()`, which collects until the first element and then
stops. The channel had kept the event since `onAdd` sent it, with nobody listening, which is the
property section 06 relied on.

The whole run, the four test classes of this lesson, six tests in all:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E '^BUILD'
BUILD SUCCESSFUL in 17s
ana@vm:~/planner$ grep -ho "testsuite name=\"[a-zA-Z.]*\" tests=\"[0-9]*\" skipped=\"[0-9]*\" failures=\"[0-9]*\"" app/build/test-results/testDebugUnitTest/*.xml
testsuite name="com.example.planner.SnackbarTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.SubscriptionTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.ui.CancelTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.ui.WeekViewModelTest" tests="3" skipped="0" failures="0"
```
