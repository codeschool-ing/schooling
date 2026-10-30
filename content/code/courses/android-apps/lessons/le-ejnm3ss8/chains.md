---
title: Chains, and what a retry holds up
version: 1
---

**A chain is several requests in an order, where each one starts only when the one before it has
succeeded**, and receives its output as input. The planner uses one when the student presses
"sync now": send the sessions, then build the sentence the screen shows about it. The second step
needs the number the first one produced, and has nothing to do if the first did not happen.

The second worker reads the first one's output:

```kotlin
// app/src/main/java/com/example/planner/work/SummaryWorker.kt
package com.example.planner.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf

class SummaryWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val sent = inputData.getInt(SyncWorker.KEY_SENT, -1)
        if (sent < 0) return Result.failure()
        return Result.success(workDataOf(KEY_MESSAGE to "$sent sessions synced"))
    }

    companion object {
        const val KEY_MESSAGE = "message"
    }
}
```

It has only the two standard parameters, so `PlannerWorkerFactory` returns `null` for it and
WorkManager builds it by reflection, as section 03 said. `Data` is meant for small values, a few
numbers or a short string: WorkManager stores it in its database and caps it at 10 KB. A list of
sessions does not go in `Data`; the worker reads it from where the sessions are kept.

## One-time requests in a unique chain

```kotlin
// app/src/test/java/com/example/planner/work/ChainTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.Configuration
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import java.io.IOException
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ChainTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()
    private var serverUp = true

    @Before fun setUp() {
        val config = Configuration.Builder()
            .setExecutor(SynchronousExecutor())
            .setWorkerFactory(PlannerWorkerFactory {
                if (serverUp) 3 else throw IOException("no route to host")
            })
            .build()
        WorkManagerTestInitHelper.initializeTestWorkManager(context, config)
    }

    private fun syncThenSummarise(): Pair<String, String> {
        val wm = WorkManager.getInstance(context)
        val sync = OneTimeWorkRequestBuilder<SyncWorker>().build()
        val summary = OneTimeWorkRequestBuilder<SummaryWorker>().build()
        wm.beginUniqueWork("sync-now", ExistingWorkPolicy.REPLACE, sync).then(summary).enqueue()
        val s = wm.getWorkInfoById(sync.id).get()!!
        val m = wm.getWorkInfoById(summary.id).get()!!
        return "sync ${s.state} (attempts ${s.runAttemptCount})" to
            "summary ${m.state} ${m.outputData.getString(SummaryWorker.KEY_MESSAGE) ?: ""}"
    }

    @Test fun theOutputOfOneIsTheInputOfTheNext() {
        println(syncThenSummarise())
    }

    @Test fun aRetryHoldsEverythingAfterIt() {
        serverUp = false
        println(syncThenSummarise())
    }
}
```

`beginUniqueWork` names the chain, as section 04 named the periodic request, and `REPLACE` is the
policy a button wants: a second press cancels the chain still waiting and starts a fresh one, so two
presses never send twice. These requests have no constraints, so with the synchronous executor they
run the moment they are enqueued:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ChainTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    (sync SUCCEEDED (attempts 1), summary SUCCEEDED 3 sessions synced)
ChainTest > theOutputOfOneIsTheInputOfTheNext PASSED
    (sync ENQUEUED (attempts 1), summary BLOCKED )
ChainTest > aRetryHoldsEverythingAfterIt PASSED
BUILD SUCCESSFUL in 17s
```

With the server up, the sync ran once and succeeded, and the summary received `sent` as its input
and produced the sentence. **With the server down, the summary is `BLOCKED`**: it is waiting for the
request before it, which asked for a retry and is `ENQUEUED` again after its first attempt. When the
back-off delay passes and the retry succeeds, the summary runs. If the sync had answered `failure`
instead, WorkManager would mark everything after it as failed too, without running it.

## The states, all of them

A request moves through six states, and the tests in this lesson have now shown three of them:

| state | what it means |
|---|---|
| `ENQUEUED` | waiting for its constraints, its delay or its next period |
| `BLOCKED` | waiting for the request before it in a chain |
| `RUNNING` | `doWork` is executing now |
| `SUCCEEDED` | finished with success; a one-time request only |
| `FAILED` | finished with failure, or a request before it failed |
| `CANCELLED` | cancelled by the app, or replaced by `REPLACE` |

The app reads these with `getWorkInfosForUniqueWorkFlow`, a `Flow` that lesson 11's
`collectAsStateWithLifecycle` turns into state on screen: a small "syncing" line while the chain is
`RUNNING`, and the summary's sentence once it has `SUCCEEDED`.
