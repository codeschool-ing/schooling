---
title: A worker, and the three answers it can give
version: 1
---

**A worker is a class with one function, `doWork`, and that function ends by saying one of three
things**: it succeeded, it failed for good, or it should be tried again later. Everything else in
WorkManager, the conditions, the schedule and the retries, exists to decide when `doWork` is called
and what to do with its answer.

Start from lesson 1's project and add WorkManager to the module. This is the whole build file, with
two lines added for the library and its test helper, one for coroutine tests, and a `testLogging`
block that prints what each test writes, so that you see the same lines this section shows:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)
    implementation(libs.work.runtime.ktx)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.work.testing)
    testImplementation(libs.coroutines.test)
}
```

## The thing the worker calls

The worker should not know how sessions reach the server; lesson 13 builds that with Retrofit, and
lesson 16 puts it behind a repository. It needs one function to call, so it gets one:

```kotlin
// app/src/main/java/com/example/planner/data/Uploader.kt
package com.example.planner.data

import java.io.IOException

/** Sends the sessions the server has not seen yet, and says how many went. */
fun interface Uploader {
    @Throws(IOException::class)
    suspend fun upload(): Int
}
```

`IOException` is the family of failures that a later attempt can fix: no network, a timeout, a
connection the server dropped. That distinction is the whole of the worker's decision.

## The worker

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/work/SyncWorker.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/work/SyncWorker.kt\npackage com.example.planner.work\n\nimport android.content.Context\nimport androidx.work.CoroutineWorker\nimport androidx.work.WorkerParameters\nimport androidx.work.workDataOf\nimport com.example.planner.data.Uploader\nimport java.io.IOException"}, {"code": "\nclass SyncWorker(\n    context: Context,\n    params: WorkerParameters,\n    private val uploader: Uploader,\n) : CoroutineWorker(context, params) {", "note": "`CoroutineWorker` makes `doWork` a `suspend` function, run on `Dispatchers.Default`. The first two parameters are WorkManager's; the third is ours, and section 06 shows who passes it."}, {"code": "\n    override suspend fun doWork(): Result {\n        return try {\n            val sent = uploader.upload()\n            Result.success(workDataOf(KEY_SENT to sent))", "note": "**Success** carries output: a small `Data` map of keys and simple values. WorkManager stores it with the result, and section 05 hands it to the next worker."}, {"code": "        } catch (e: IOException) {\n            if (runAttemptCount < MAX_ATTEMPTS - 1) Result.retry() else Result.failure()\n        }\n    }", "note": "**Retry** puts the work back in the queue, to run again after a back-off delay. `runAttemptCount` counts the runs before this one, so three attempts are 0, 1 and 2, and the third gives up with **failure**."}, {"code": "\n    companion object {\n        const val KEY_SENT = \"sent\"\n        const val MAX_ATTEMPTS = 3\n    }\n}", "note": "The key is a constant because the worker that reads this output is in another file."}]}
```

Any other exception escaping `doWork` counts as a failure. That is the right default: an
`IllegalStateException` will be thrown the same way on the next attempt, and retrying it only spends
the battery.

## Who builds the worker

WorkManager creates workers itself, by class name, and by default it only knows the constructor with
two parameters. A worker with a dependency needs a **factory**, which WorkManager asks first:

```kotlin
// app/src/main/java/com/example/planner/work/PlannerWorkerFactory.kt
package com.example.planner.work

import android.content.Context
import androidx.work.ListenableWorker
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import com.example.planner.data.Uploader

class PlannerWorkerFactory(private val uploader: Uploader) : WorkerFactory() {
    override fun createWorker(
        appContext: Context,
        workerClassName: String,
        workerParameters: WorkerParameters,
    ): ListenableWorker? = when (workerClassName) {
        SyncWorker::class.java.name -> SyncWorker(appContext, workerParameters, uploader)
        else -> null
    }
}
```

**Returning `null` is not an error**: it tells WorkManager to fall back to its own reflection, which
is how a worker with the two standard parameters is still created. With Hilt, lesson 12's library,
`@HiltWorker` and the `hilt-work` artefact in the catalogue generate this factory for you.

## Testing it, one attempt at a time

`TestListenableWorkerBuilder` builds one worker as WorkManager would, with whatever attempt count the
test asks for, and `doWork` is then an ordinary `suspend` call:

```kotlin
// app/src/test/java/com/example/planner/work/SyncWorkerTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker.Result
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import com.example.planner.data.Uploader
import java.io.IOException
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SyncWorkerTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()

    private fun worker(attempt: Int, uploader: Uploader) =
        TestListenableWorkerBuilder<SyncWorker>(context)
            .setRunAttemptCount(attempt)
            .setWorkerFactory(PlannerWorkerFactory(uploader))
            .build()

    @Test fun sendsAndReportsHowMany() = runTest {
        val result = worker(0) { 4 }.doWork()
        println("attempt 0, server up: $result")
        assertEquals(Result.success(workDataOf(SyncWorker.KEY_SENT to 4)), result)
    }

    @Test fun retriesWhileAttemptsRemain() = runTest {
        for (attempt in 0..2) {
            val result = worker(attempt) { throw IOException("no route to host") }.doWork()
            println("attempt $attempt, server down: $result")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*SyncWorkerTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    attempt 0, server up: Success {mOutputData=Data {sent : 4}}
SyncWorkerTest > sendsAndReportsHowMany PASSED
    attempt 0, server down: Retry
    attempt 1, server down: Retry
    attempt 2, server down: Failure {mOutputData=Data {}}
SyncWorkerTest > retriesWhileAttemptsRemain PASSED
BUILD SUCCESSFUL in 20s
```

The three answers, each where it should be. With the server up, the output carries `sent : 4`. With
the server down, attempts 0 and 1 ask to be retried and attempt 2 gives up. **A failure is final**:
WorkManager will not run that request again. A retry is the opposite, and section 05 shows what it
does to the work queued behind it.
