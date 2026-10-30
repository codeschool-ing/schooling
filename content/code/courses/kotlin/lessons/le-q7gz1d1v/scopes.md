---
title: A scope: no coroutine outlives the work it belongs to
version: 1
---

Lesson 14 ended with a rule: `runBlocking` waits for every coroutine launched inside it. **That rule
is the whole of structured concurrency**: every coroutine is started inside a scope, the scope does
not finish until all of them have, and so no coroutine can be forgotten, left running after the code
that started it has moved on.

`coroutineScope { … }` creates such a scope inside a suspending function. It is how a function that
starts coroutines keeps the promise that, when it returns, it is really finished:

```kotlin
// src/main/kotlin/Scope.kt
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

private suspend fun fetchCourse(name: String, ms: Long): String {
    delay(ms)
    println("  loaded $name")
    return name
}

suspend fun loadPlan(): List<String> = coroutineScope {
    val kotlin = async { fetchCourse("Kotlin", 300) }
    val android = async { fetchCourse("Android", 100) }
    listOf(kotlin.await(), android.await())
}

fun main() = runBlocking {
    println("loading")
    val plan = loadPlan()
    println("plan: $plan")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ScopeKt
e: file:///home/ana/kt/planner/src/main/kotlin/Global.kt:9:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Swallow.kt:7:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Timeout.kt:13:1 Conflicting overloads:
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Kotlin compiler: CONFLICTING_OVERLOADS
       Kotlin compiler error
         Conflicting overloads:
         fun main(): Any
         Location: /home/ana/kt/planner/src/main/kotlin/Global.kt:9

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

`loadPlan` starts two coroutines and returns only when both are done; its caller cannot tell that it
used coroutines at all. **From outside, a function with a `coroutineScope` in it is just a `suspend`
function that takes a while.** That is what makes concurrency composable: `loadPlan` can be called
from anywhere a suspending function can, and nothing it started leaks out.

`fetchCourse` is `private`, because lessons 14 to 17 share one project and a top-level name has to be
unique in it; lesson 14's `Async.kt` showed what happens otherwise.

## The tree

Every coroutine started in a scope becomes a **child** of that scope's job, and the jobs form a tree:
`runBlocking` at the root, `coroutineScope` under it, the two `async`s under that. The tree is what
makes the next three sections work. **Cancellation travels down it**, from a parent to every child;
**failure travels up it**, from a child to its parent, which then cancels the other children.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l15-tree\" aria-label=\"A tree of jobs. runBlocking at the root, coroutineScope below it, and three children below that: sync reminders, read calendar, export week. The read calendar child fails. An arrow carries its failure up to coroutineScope. Arrows from coroutineScope carry cancellation down to the two other children. Then coroutineScope throws the failure up to runBlocking. A note: failure travels up, cancellation travels down.\"><defs><marker id=\"l15-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-tree-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"280\" y=\"14\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">runBlocking</text><rect x=\"270\" y=\"84\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">coroutineScope</text><path d=\"M360 50 L360 82\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sync reminders</text><rect x=\"280\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read calendar</text><rect x=\"520\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">export week</text><path d=\"M360 120 L120 168\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360 120 L600 168\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M345 168 L345 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-tree-ah-amber)\"></path><text x=\"300\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">fails</text><path d=\"M330 122 L150 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l15-tree-ah-paper-dim)\"></path><path d=\"M392 122 L570 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l15-tree-ah-paper-dim)\"></path><text x=\"200\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelled</text><text x=\"520\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelled</text><path d=\"M378 82 L378 52\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-tree-ah-amber)\"></path><text x=\"470\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">rethrown to the caller</text><text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">failure travels up, cancellation travels down</text></svg>", "caption": "Coroutines form a tree of jobs: a failure goes up to the scope, which cancels the other children and then rethrows."}
```
