---
title: Um Flow é uma sequência que pode suspender
version: 1
---

Uma função suspensa devolve um valor, uma vez. O planejador tem valores que chegam ao longo do tempo:
sessões lidas de um registro uma a uma, um cronômetro batendo, a semana mudando enquanto a estudante
estuda. **Um `Flow` é um fluxo de valores produzidos por código suspenso**: a sequência da aula 5, com
direito a `delay` entre os itens, e é o tipo que o `android-apps` usa para tudo o que uma tela observa.

```kotlin
// src/main/kotlin/FlowCold.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking

private fun sessionLog(): Flow<Int> = flow {
    println("  opening the log")
    for (minutes in listOf(45, 30, 60)) {
        delay(100)
        emit(minutes)
    }
}

fun main() = runBlocking {
    val week = sessionLog()
    println("flow created, nothing read yet")
    week.collect { println("got $it") }
    println("collecting again:")
    week.collect { println("again $it") }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowColdKt
flow created, nothing read yet
  opening the log
got 45
got 30
got 60
collecting again:
  opening the log
again 45
again 30
again 60
```

`flow { … }` monta um flow a partir de um bloco de código suspenso; o `emit` entrega um valor a quem
estiver coletando. **Chamar `sessionLog()` não rodou nada desse bloco**: `flow created` foi impresso
antes de o registro ser aberto. O bloco rodou quando o `collect` pediu valores, e cada valor foi para a
lambda do `collect` assim que foi emitido, com cem milissegundos de intervalo.

## Frio: cada coletor ganha a própria execução

O segundo `collect` imprimiu `opening the log` de novo e recebeu os três valores de novo. **Um flow
montado assim é frio: não faz nada até ser coletado, e cada coleta roda o produtor desde o começo.** É a
preguiça da aula 5, estendida ao tempo, e é o que torna seguro definir um flow uma vez e passá-lo
adiante: defini-lo não custa nada, e ninguém divide um registro lido pela metade.

O oposto, um fluxo quente que produz haja ou não quem escute e divide os valores entre os ouvintes, é o
`StateFlow` e o `SharedFlow` da aula 17.

## O `collect` suspende

O `collect` é uma função suspensa, e só retorna quando o flow termina de emitir. É por isso que
`collecting again:` foi impresso depois do terceiro `got`: **o código depois de um `collect` roda quando o
fluxo acaba**, o que, para um flow que nunca termina, um cronômetro, é nunca. Uma tela que coleta um flow
assim faz isso numa corrotina própria, como a aula 17 mostra.
