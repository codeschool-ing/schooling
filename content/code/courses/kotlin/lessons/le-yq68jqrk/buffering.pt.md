---
title: Um coletor lento: buffer e conflate
version: 1
---

Por padrão, o produtor e o coletor de um flow se revezam: o produtor emite, o coletor trata o valor, e
só então o produtor segue. **Com um coletor lento, o produtor passa a maior parte do tempo esperando.**
Dois operadores mudam isso, e respondem a perguntas diferentes.

```kotlin
// src/main/kotlin/FlowBuffer.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking
import kotlin.time.measureTime

private fun ticks(): Flow<Int> = flow {
    for (i in 1..5) {
        delay(100)
        emit(i)
    }
}

private suspend fun slowly(label: String, source: Flow<Int>) {
    val seen = mutableListOf<Int>()
    val took = measureTime {
        source.collect {
            delay(300)
            seen += it
        }
    }
    println("$label saw $seen in about ${(took.inWholeMilliseconds + 50) / 100 * 100} ms")
}

fun main() = runBlocking {
    slowly("plain   ", ticks())
    slowly("buffer  ", ticks().buffer())
    slowly("conflate", ticks().conflate())
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowBufferKt
plain    saw [1, 2, 3, 4, 5] in about 2000 ms
buffer   saw [1, 2, 3, 4, 5] in about 1600 ms
conflate saw [1, 3, 5] in about 1000 ms
```

O produtor emite a cada 100 milissegundos e o coletor leva 300 por valor. Os tempos são arredondados
para a centena mais próxima, porque o número exato varia alguns milissegundos entre execuções.

- **Simples**, os dois se revezam, então cada valor custa 100 mais 300: cerca de dois segundos para cinco.
- **`buffer()`** roda o produtor numa corrotina própria, com uma fila entre os dois, então ele emite os
  cinco sem esperar e o coletor vai trabalhando a fila. Todo valor chega, e o total é o tempo do coletor
  mais o primeiro tick.
- **`conflate()`** guarda só o valor mais recente: o que foi emitido enquanto o coletor estava ocupado
  substitui o que estava esperando. O coletor viu menos valores e terminou antes.

## Qual deles

**`buffer` quando todo valor importa**, cada sessão gravada em disco, cada mensagem enviada. **`conflate`
quando só o mais recente importa**: uma tela que mostra o total atual não tem uso para um total que já
estava desatualizado quando foi desenhado. O `StateFlow` da lição 17 se comporta como se fosse
`conflate`, exatamente por esse motivo.
