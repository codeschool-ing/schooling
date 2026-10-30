---
title: O cancelamento é cooperativo
version: 1
---

O `job.cancel()` não para uma corrotina por fora. **Ele marca uma flag, e a corrotina para na próxima
vez que verificar**: toda função suspensa do `kotlinx.coroutines`, o `delay` incluso, verifica, e lança
`CancellationException` se a flag estiver marcada. A exceção desenrola a corrotina como qualquer outra,
então os blocos `finally` rodam e a corrotina consegue fazer a limpeza.

```kotlin
// src/main/kotlin/Cancel.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val timer = launch {
        try {
            var elapsed = 0
            while (true) {
                delay(100)
                elapsed += 100
                println("studied $elapsed ms")
            }
        } finally {
            println("timer stopped, saving the session")
        }
    }
    delay(350)
    timer.cancelAndJoin()
    println("timer cancelled: ${timer.isCancelled}")

    val busy = launch(Dispatchers.Default) {
        val end = System.currentTimeMillis() + 300
        while (System.currentTimeMillis() < end) { }
        println("busy loop ran to the end anyway")
    }
    delay(50)
    busy.cancelAndJoin()

    val polite = launch(Dispatchers.Default) {
        val end = System.currentTimeMillis() + 300
        while (System.currentTimeMillis() < end) {
            ensureActive()
        }
        println("never printed")
    }
    delay(50)
    polite.cancelAndJoin()
    println("polite loop stopped early")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=CancelKt
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

O cronômetro foi cancelado durante o quarto `delay`, que lançou exceção, o `finally` rodou, e o laço
nunca imprimiu `400`. `cancelAndJoin()` é `cancel()` seguido de `join()`, então o `main` esperou a
limpeza antes de imprimir.

**O laço ocupado ignorou o cancelamento por completo.** Ele nunca suspendeu, então nunca verificou, e
rodou os 300 milissegundos inteiros e imprimiu a linha dele. Uma corrotina que faz trabalho longo sem
suspender precisa verificar à mão: o `ensureActive()` lança `CancellationException` se a corrotina foi
cancelada, e o laço educado parou na verificação seguinte. O `isActive`, uma propriedade, é a mesma
informação como `Boolean` para a condição de um laço.

## Limpando depois do cancelamento

Um bloco `finally` roda numa corrotina já cancelada, então **chamar uma função suspensa nele lança
exceção de novo na hora**. Salvar uma sessão num arquivo com uma função suspensa ali precisa de
`withContext(NonCancellable) { … }`, que roda o bloco como se a corrotina não tivesse sido cancelada.
Use só para uma limpeza curta: um bloco que não pode ser cancelado é um bloco que ninguém consegue
parar.
