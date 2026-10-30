---
title: Dois jeitos de quebrar a estrutura
version: 1
---

A concorrência estruturada se mantém enquanto duas coisas forem verdade: toda corrotina é iniciada num
escopo que a espera, e o cancelamento tem permissão para viajar. Cada uma tem um jeito comum de ser
quebrada.

## Engolindo o cancelamento

A aula 13 avisou que o `runCatching` pega tudo. Numa corrotina, tudo inclui a
`CancellationException`:

```kotlin
// src/main/kotlin/Swallow.kt
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val job = launch {
        repeat(5) { i ->
            runCatching { delay(100) }
            println("tick $i")
        }
    }
    delay(150)
    job.cancelAndJoin()
    println("after cancel")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SwallowKt
tick 0
tick 1
tick 2
tick 3
tick 4
after cancel
```

O job foi cancelado durante o segundo `delay`. Esse `delay` lançou `CancellationException`, o
`runCatching` a pegou, e o laço seguiu: **todo `delay` restante lançou na hora e foi pego na hora**,
então os ticks 1 a 4 saíram de uma vez depois do cancelamento. O job terminou, porque o laço acabou, e
um laço sem fim nunca teria terminado. A solução é deixar o cancelamento passar: pegue as exceções
específicas que o bloco pode de fato lançar, ou relance uma `CancellationException` quando pegar algo
mais largo.

## GlobalScope

O `GlobalScope` é um escopo que não pertence a nada e não espera nada. Uma corrotina iniciada nele não é
filha do código que a iniciou:

```kotlin
// src/main/kotlin/Global.kt
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

@OptIn(DelicateCoroutinesApi::class)
fun main() = runBlocking {
    GlobalScope.launch {
        delay(100)
        println("session saved")
    }
    println("main finished")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=GlobalKt
main finished
```

O `runBlocking` não a esperou, porque ela não é filha dele, e o programa terminou antes de a sessão ser
salva. Nada relatou a perda. **Esse é o bug que a concorrência estruturada existe para impedir**, e a
biblioteca marca o `GlobalScope` como uma API delicada: sem a linha `@OptIn` o compilador avisa, então
usá-lo é uma decisão que alguém escreveu. No Android, um trabalho lançado assim também sobrevive à tela
que o iniciou e continua rodando depois de a estudante ter saído. Lance no escopo dono do trabalho, um
`coroutineScope`, ou no escopo que um framework lhe dá.
