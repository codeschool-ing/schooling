---
title: Constraints, periods, and asking for the same work twice
version: 1
---

**A request is the worker plus the conditions under which it may run.** The worker of section 03
says what to do; the request says when it is allowed to, how often, and what to do with a retry.
The planner wants its sessions sent every few hours, only with a network, and not when the battery
is nearly empty:

```kotlin
// app/src/main/java/com/example/planner/work/Sync.kt
package com.example.planner.work

import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

const val SYNC_WORK = "sync-sessions"

fun scheduleSync(workManager: WorkManager) {
    val constraints = Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .setRequiresBatteryNotLow(true)
        .build()
    val request = PeriodicWorkRequestBuilder<SyncWorker>(6, TimeUnit.HOURS)
        .setConstraints(constraints)
        .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
        .build()
    workManager.enqueueUniquePeriodicWork(SYNC_WORK, ExistingPeriodicWorkPolicy.KEEP, request)
}
```

Three decisions are in that function, one per call:

- **`Constraints`** are checked by the system, not by your code. `CONNECTED` means any network;
  `UNMETERED` would wait for Wi-Fi, which suits a large upload and is wrong for a few sessions.
  `setRequiresBatteryNotLow` lets the student's battery decide before the planner does.
- **`PeriodicWorkRequestBuilder`** with six hours repeats the work about every six hours, for as long
  as the app is installed. "About" is meant: the system runs it once in each period, at a moment of
  its choosing.
- **`setBackoffCriteria`** says how long a retry waits: 30 seconds after the first, and doubling each
  time, which is what `EXPONENTIAL` means. The alternative, `LINEAR`, adds 30 seconds each time.

## Unique work, because `onCreate` runs more than once

`scheduleSync` will be called from the application's `onCreate`, in section 06, and that runs every
time the process starts. Plain `enqueue` would add a new periodic request on every start, and after
a week the planner would be sending its sessions twenty times every six hours. **Unique work gives
the request a name**, and the policy says what a second request with the same name does: `KEEP`
leaves the existing one alone, and `UPDATE` replaces its definition while keeping its schedule.

## Testing time and conditions without waiting for either

`WorkManagerTestInitHelper` puts a test WorkManager in place of the real one, with a
`SynchronousExecutor` so that work runs on the test's own thread. Its **test driver** is what makes the
test possible: it tells WorkManager that the constraints are met, or that a period has passed, without
waiting six hours.

```kotlin
// app/src/test/java/com/example/planner/work/ScheduleTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.Configuration
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ScheduleTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()
    private var uploads = 0

    @Before fun setUp() {
        val config = Configuration.Builder()
            .setExecutor(SynchronousExecutor())
            .setWorkerFactory(PlannerWorkerFactory { uploads++; 2 })
            .build()
        WorkManagerTestInitHelper.initializeTestWorkManager(context, config)
    }

    private fun info(wm: WorkManager): WorkInfo =
        wm.getWorkInfosForUniqueWork(SYNC_WORK).get().single()

    @Test fun waitsForItsConstraintsEveryPeriod() {
        val wm = WorkManager.getInstance(context)
        scheduleSync(wm)
        val id = info(wm).id
        val driver = WorkManagerTestInitHelper.getTestDriver(context)!!
        println("enqueued:              ${info(wm).state}, uploads = $uploads")
        driver.setAllConstraintsMet(id)
        println("network and battery:   ${info(wm).state}, uploads = $uploads")
        driver.setPeriodDelayMet(id)
        println("six hours later:       ${info(wm).state}, uploads = $uploads")
        driver.setAllConstraintsMet(id)
        println("network and battery:   ${info(wm).state}, uploads = $uploads")
        assertEquals(2, uploads)
    }

    @Test fun keepLeavesTheFirstRequestAlone() {
        val wm = WorkManager.getInstance(context)
        scheduleSync(wm)
        val first = info(wm).id
        scheduleSync(wm)
        scheduleSync(wm)
        val all = wm.getWorkInfosForUniqueWork(SYNC_WORK).get()
        println("after three calls: ${all.size} request, same id = ${all.single().id == first}")
    }

    @Test fun fifteenMinutesIsTheFloor() {
        val request = PeriodicWorkRequestBuilder<SyncWorker>(5, TimeUnit.MINUTES).build()
        println("asked for 5 minutes, got ${request.workSpec.intervalDuration / 60_000}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.waits*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    enqueued:              ENQUEUED, uploads = 0
    network and battery:   ENQUEUED, uploads = 1
    six hours later:       ENQUEUED, uploads = 1
    network and battery:   ENQUEUED, uploads = 2
ScheduleTest > waitsForItsConstraintsEveryPeriod PASSED
BUILD SUCCESSFUL in 16s
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.keep*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    after three calls: 1 request, same id = true
ScheduleTest > keepLeavesTheFirstRequestAlone PASSED
BUILD SUCCESSFUL in 10s
```

Read the first test line by line, because it holds the one thing about periodic work that surprises
people. Enqueued, nothing runs: no network has been declared. Constraints met, the upload runs once,
and the state goes back to `ENQUEUED`, **because a periodic request never reaches `SUCCEEDED`**; it
succeeds and waits for its next period. Six hours later, nothing happens on its own. **Each period
waits for its constraints again**, and only when the test says the network is there does the second
upload run.

The second test is the `KEEP` policy: three calls, one request, and it is the first one.

## Fifteen minutes is the floor

A period cannot be as short as you like. The third test asks for five minutes and looks at what was
built:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.fifteen*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    asked for 5 minutes, got 15
ScheduleTest > fifteenMinutesIsTheFloor PASSED
BUILD SUCCESSFUL in 13s
```

**Fifteen minutes is the shortest period WorkManager will schedule**, and it raises a shorter one
rather than refusing it. Anything that has to happen more often than that while the app is
closed is a sign the design is wrong: a server can push a message instead, which is
`mobile-fundamentals` lesson 17's subject.
