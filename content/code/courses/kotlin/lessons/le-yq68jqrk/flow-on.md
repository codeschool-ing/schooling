---
title: flowOn: where the producer runs
version: 1
---

A flow's producer runs in the coroutine that collects it, on that coroutine's dispatcher. A screen
collecting on Android's main thread would then read files on the main thread, which lesson 14 said
freezes the app. **`flowOn(dispatcher)` moves everything upstream of it to another dispatcher**, and
leaves the collector where it was:

```kotlin
// src/main/kotlin/FlowOn.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking

private fun threadName() = Thread.currentThread().name.substringBefore(" @")

fun main() = runBlocking {
    flow {
        for (line in listOf("45", "30")) {
            println("reading $line on ${threadName()}")
            emit(line)
        }
    }
        .map { it.toInt() }
        .flowOn(Dispatchers.IO)
        .collect { println("collected $it on ${threadName()}") }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowOnKt
reading 45 on DefaultDispatcher-worker-1
reading 30 on DefaultDispatcher-worker-1
collected 45 on main
collected 30 on main
```

The reading ran on an IO worker and the collecting on `main`. `flowOn` applies to the operators
**above** it, here the `flow` block and the `map`; anything added below it would run on the
collector's dispatcher. The library runs the two halves as separate coroutines with a channel between
them, which is what lets the producer go on reading while the collector handles a value.

## The rule `flowOn` replaces

Switching dispatcher inside the `flow` block, the obvious way, is refused:

```kotlin
// src/main/kotlin/FlowWrong.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

fun main() = runBlocking {
    flow {
        withContext(Dispatchers.IO) {
            emit(45)
        }
    }.collect { println(it) }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowWrongKt
Exception in thread "main" java.lang.IllegalStateException: Flow invariant is violated:
		Flow was collected in [BlockingCoroutine{Active}@581f07e4, BlockingEventLoop@20e68760],
		but emission happened in [DispatchedCoroutine{Active}@7e56ca28, Dispatchers.IO].
		Please refer to 'flow' documentation or use 'flowOn' instead
	at kotlinx.coroutines.flow.internal.SafeCollector_commonKt.checkContext(SafeCollector.common.kt:84)
	at kotlinx.coroutines.flow.internal.SafeCollector.checkContext(SafeCollector.kt:132)
	at kotlinx.coroutines.flow.internal.SafeCollector.emit(SafeCollector.kt:109)
	at kotlinx.coroutines.flow.internal.SafeCollector.emit(SafeCollector.kt:82)
	at FlowWrongKt$main$1$1$1.invokeSuspend(FlowWrong.kt:10)
	at kotlin.coroutines.jvm.internal.BaseContinuationImpl.resumeWith(ContinuationImpl.kt:34)
	at kotlinx.coroutines.DispatchedTask.run(DispatchedTask.kt:100)
	at kotlinx.coroutines.internal.LimitedDispatcher$Worker.run(LimitedDispatcher.kt:124)
	at kotlinx.coroutines.scheduling.TaskImpl.run(Tasks.kt:89)
	at kotlinx.coroutines.scheduling.CoroutineScheduler.runSafely(CoroutineScheduler.kt:586)
	at kotlinx.coroutines.scheduling.CoroutineScheduler$Worker.executeTask(CoroutineScheduler.kt:798)
	at kotlinx.coroutines.scheduling.CoroutineScheduler$Worker.runWorker(CoroutineScheduler.kt:717)
	at kotlinx.coroutines.scheduling.CoroutineScheduler$Worker.run(CoroutineScheduler.kt:704)

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':run' (registered by plugin 'org.gradle.application').
> Process 'command '/usr/lib/jvm/java-21-openjdk-amd64/bin/java'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 2s
```

**A flow must emit from the coroutine it was collected in.** The message names the rule, the two
coroutines involved, and the fix: `flowOn`. The rule is what guarantees that a collector's lambda
always runs where the collector expects, so a screen collecting on the main thread can touch the screen
from its lambda safely.
