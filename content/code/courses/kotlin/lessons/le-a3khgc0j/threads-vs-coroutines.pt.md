---
title: Cem mil corrotinas
version: 1
---

A afirmação por trás das corrotinas é que elas são baratas: **uma corrotina suspensa é um pequeno objeto
no heap, não uma thread com pilha própria**. Uma thread na JVM reserva a pilha, meio megabyte ou mais,
desde o momento em que começa, e o sistema operacional escalona cada uma delas. Um programa pode ter
milhares de threads; pode ter centenas de milhares de corrotinas.

```kotlin
// src/main/kotlin/Many.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.measureTime

fun main() {
    val done = AtomicInteger()
    val took = measureTime {
        runBlocking {
            repeat(100_000) {
                launch {
                    delay(1000)
                    done.incrementAndGet()
                }
            }
        }
    }
    println("${done.get()} coroutines finished")
    println("in about ${took.inWholeMilliseconds / 1000} s, on one thread")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ManyKt
100000 coroutines finished
in about 1 s, on one thread
```

Cem mil corrotinas esperaram um segundo cada, e o programa inteiro levou cerca de um segundo, na única
thread que o `runBlocking` usa. **Toda corrotina estava suspensa no `delay` ao mesmo tempo**, o que
custou a cada uma um pequeno objeto e nada mais. O `AtomicInteger` é um contador seguro de incrementar a
partir de vários lugares, de que este programa a rigor não precisa numa thread só e que se torna
necessário no momento em que as corrotinas passam para o `Dispatchers.Default`.

## Quanto custaria com threads

O mesmo programa com `thread { Thread.sleep(1000) }` no lugar de `launch { delay(1000) }` pede ao sistema
operacional cem mil threads. Dependendo dos limites da máquina, ele ocupa gigabytes de memória com as
pilhas ou falha com `OutOfMemoryError: unable to create native thread`. Ele não foi executado na
gravação deste curso, porque um programa feito para esgotar a máquina de gravação não é uma
demonstração que compense o risco; você pode tentar na sua máquina com um número menor e ver a memória
subir.

O Java 21 tem threads virtuais, que aplicam a mesma ideia à própria `Thread`. **As corrotinas acrescentam
o que as threads virtuais não têm**: concorrência estruturada, cancelamento que se propaga e o `Flow`,
que são as lições 15 a 17, e rodam sem mudança no Android, onde threads virtuais não estão disponíveis.
