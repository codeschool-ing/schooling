---
title: Operadores terminais: coletando um resultado
version: 1
---

O `collect` é um jeito de terminar um flow. **Um operador terminal é uma função suspensa que roda o flow
e devolve algo que não é um flow**, e a biblioteca tem os que você esperaria da aula 5:

```kotlin
// src/main/kotlin/FlowTerminal.kt
import kotlinx.coroutines.flow.count
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.fold
import kotlinx.coroutines.flow.runningFold
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val week = flowOf(45, 30, 60)
    println(week.toList())
    println(week.first())
    println(week.fold(0) { total, m -> total + m })
    println(week.count { it >= 45 })
    println(week.runningFold(0) { total, m -> total + m }.toList())
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowTerminalKt
[45, 30, 60]
45
135
2
[0, 45, 75, 135]
```

O `flowOf` monta um flow de valores fixos. Cada linha rodou o flow de novo, porque ele é frio, e cada
operador terminal o coletou do seu jeito. O `first()` parou o flow depois de um valor, como `take(1)`;
`fold` e `count` coletaram os três. O `runningFold` não é terminal: é um operador que emite cada total
acumulado, e o `toList()` depois dele é que os coletou.

| terminal | devolve |
|---|---|
| `collect { … }` | `Unit`, quando o flow termina |
| `toList()`, `toSet()` | todo valor |
| `first()`, `firstOrNull()` | o primeiro valor, e cancela o resto |
| `fold`, `reduce` | um valor acumulado |
| `count` | quantos valores passaram no teste |

## Quando coletar numa lista

O `toList()` espera o flow terminar. **Num flow que nunca termina, um operador terminal que precisa de
todo valor nunca retorna**, e a corrotina espera para sempre. O `toList()` é certo para um flow que se
sabe finito, as linhas de um arquivo, uma página de resultados, e errado para qualquer coisa que
represente um valor mudando ao longo do tempo, que é coletado valor a valor conforme chega.
