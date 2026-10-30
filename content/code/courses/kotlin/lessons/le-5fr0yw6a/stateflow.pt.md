---
title: StateFlow: um valor que se observa
version: 1
---

`StateFlow<T>` é um flow quente com três regras, e cada uma existe por causa de como uma tela usa
estado.

| regra | por quê |
|---|---|
| ele sempre tem um valor, então precisa de um para começar | uma tela desenhada antes de qualquer coisa carregar ainda tem o que desenhar |
| um coletor novo recebe primeiro o valor atual | uma tela que abre tarde fica em dia na hora |
| valores iguais não são emitidos duas vezes, e um coletor lento recebe só o mais recente | redesenhar sem mudança, ou para um valor já substituído, é trabalho jogado fora |

A terceira regra é o `conflate()` da aula 16, embutido:

```kotlin
// src/main/kotlin/State.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val total = MutableStateFlow(0)
    val screen = launch {
        total.collect {
            delay(100)
            println("drew $it")
        }
    }
    delay(10)
    repeat(5) { total.value += 15 }
    delay(300)
    screen.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=StateKt
drew 0
drew 75
```

A tela desenhou 0, o valor inicial, e levou 100 milissegundos nisso. Enquanto isso o total mudou cinco
vezes. Quando a tela ficou pronta de novo, recebeu o valor mais recente, 75, e **os quatro valores do
meio nunca foram desenhados**, o que é exatamente o certo: eles estavam desatualizados antes que alguém
pudesse vê-los.

## Ler sem coletar

`total.value` lê o valor atual, de qualquer código, sem suspender. Isso torna um `StateFlow` usável em
funções comuns e em testes, e é a principal diferença prática para um flow frio: **um state flow é uma
variável que também se observa**, enquanto um flow frio é só um fluxo.
