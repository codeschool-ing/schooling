---
title: Tempos-limite
version: 1
---

Uma chamada de rede que nunca responde é uma corrotina que nunca termina, e um escopo que espera por
ela nunca termina também. **O `withTimeout(ms) { … }` cancela o bloco se ele passar do limite**, usando
o mesmo cancelamento cooperativo do `cancel()`:

```kotlin
// src/main/kotlin/Timeout.kt
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull

private suspend fun slowServer(ms: Long): List<Int> {
    delay(ms)
    return listOf(45, 30)
}

fun main() = runBlocking {
    println(withTimeoutOrNull(500) { slowServer(200) })
    println(withTimeoutOrNull(500) { slowServer(2000) })
    try {
        withTimeout(500) { slowServer(2000) }
    } catch (e: TimeoutCancellationException) {
        println("gave up: ${e.message}")
    }
    println("planner carries on")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=TimeoutKt
[45, 30]
null
gave up: Timed out waiting for 500 ms
planner carries on
```

O `withTimeoutOrNull` devolve `null` quando o tempo acaba, que o `?:` da aula 2 então responde: **use-o
quando uma resposta lenta tem um substituto sensato**, uma semana em cache, uma lista vazia. O
`withTimeout` lança `TimeoutCancellationException` no lugar, para quando o tempo acabar é uma falha que
quem chama precisa saber.

## Um tempo-limite é cancelamento

`TimeoutCancellationException` é subclasse de `CancellationException`, então tudo o que a seção de
cancelamento disse vale: o bloco para no próximo ponto de suspensão, os blocos `finally` rodam, e um
bloco que nunca suspende nunca percebe o tempo-limite. **Um tempo-limite em volta de um laço ocupado sem
`ensureActive()` roda o laço até o fim**, e só então relata que ele foi lento demais.

A última linha do `main` está ali por um motivo que vale saber. **Um `main` cuja última expressão não é
`Unit` não é ponto de entrada**, e num projeto com vários programas ele então colide com todo outro
`main`: sem aquela linha, o `try` seria o valor do `main`, do tipo `Any`, e o projeto pararia de
compilar com sobrecargas conflitantes.

O catch no `main` é estreito, de propósito. Pegar a própria `CancellationException`, ou qualquer coisa
acima dela como `Exception`, dentro de uma corrotina tem um custo que a próxima seção mostra.
