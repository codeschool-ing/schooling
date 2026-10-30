---
title: Erros num flow: catch, onCompletion e retry
version: 1
---

Um produtor pode falhar no meio: o arquivo de registro foi cortado depois de duas sessões. Uma exceção
lançada num flow desce até o coletor, e o `collect` a lança como qualquer função suspensa faria. **O
operador `catch` trata exceções de tudo o que está acima dele**, e pode emitir um valor substituto antes
de o flow terminar:

```kotlin
// src/main/kotlin/FlowErrors.kt
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.retry
import kotlinx.coroutines.runBlocking

private fun truncatedLog(): Flow<Int> = flow {
    emit(45)
    emit(30)
    throw IllegalStateException("log truncated")
}

private var attempts = 0

private fun flakyServer(): Flow<Int> = flow {
    attempts++
    println("  attempt $attempts")
    if (attempts < 3) throw IllegalStateException("server busy")
    emit(300)
}

fun main() = runBlocking {
    truncatedLog()
        .onCompletion { cause -> println("log finished, cause: ${cause?.message}") }
        .catch { e ->
            println("caught: ${e.message}")
            emit(-1)
        }
        .collect { println("got $it") }

    flakyServer()
        .retry(3)
        .collect { println("goal: $it") }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowErrorsKt
got 45
got 30
log finished, cause: log truncated
caught: log truncated
got -1
  attempt 1
  attempt 2
  attempt 3
goal: 300
```

Os dois primeiros valores chegaram, o produtor lançou exceção, o `onCompletion` viu o flow terminar com
essa causa, e o `catch` a imprimiu e emitiu `-1` no lugar. **O `onCompletion` roda seja como for que o
flow termine**, normalmente, por falha ou por cancelamento, o que o torna o `finally` do flow; a `cause`
dele é `null` num fim normal.

## O `catch` é só para cima

O `catch` pega o que acontece acima dele na corrente, e nada abaixo: uma exceção lançada dentro da
lambda do `collect` passa por ele até quem chamou. Isso é de propósito. **Um catch pertence ao lugar onde
uma falha é esperada**, do lado do produtor, e um bug no código que usa os valores deve continuar
barulhento.

## `retry`

O `retry(3)` coleta de novo o que está acima quando falha, até mais três vezes. O servidor respondeu na
terceira tentativa, e o coletor nunca viu as duas falhas. Como um flow frio roda o produtor desde o
começo a cada coleta, tentar de novo é só coletar de novo; a forma com lambda, `retry(3) { e ->
e is IOException }`, tenta de novo só as falhas que valem a pena.
