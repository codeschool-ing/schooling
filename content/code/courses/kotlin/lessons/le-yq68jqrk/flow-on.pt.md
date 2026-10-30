---
title: flowOn: onde o produtor roda
version: 1
---

O produtor de um flow roda na corrotina que o coleta, no dispatcher dela. Uma tela coletando na thread
principal do Android leria então arquivos na thread principal, o que a aula 14 disse que congela o app.
**O `flowOn(dispatcher)` leva tudo o que está acima dele para outro dispatcher**, e deixa o coletor onde
estava:

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

A leitura rodou num trabalhador de IO e a coleta no `main`. O `flowOn` vale para os operadores **acima**
dele, aqui o bloco `flow` e o `map`; qualquer coisa acrescentada abaixo dele rodaria no dispatcher do
coletor. A biblioteca roda as duas metades como corrotinas separadas com um canal entre elas, que é o
que deixa o produtor continuar lendo enquanto o coletor trata um valor.

## A regra que o `flowOn` substitui

Trocar de dispatcher dentro do bloco `flow`, o jeito óbvio, é recusado:

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

**Um flow precisa emitir da corrotina em que foi coletado.** A mensagem nomeia a regra, as duas
corrotinas envolvidas e a solução: `flowOn`. A regra é o que garante que a lambda de um coletor sempre
rode onde o coletor espera, então uma tela coletando na thread principal mexe na tela a partir da lambda
com segurança.
