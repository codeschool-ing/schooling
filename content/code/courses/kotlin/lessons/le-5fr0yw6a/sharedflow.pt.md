---
title: SharedFlow: eventos, não estado
version: 1
---

Algumas coisas que uma tela observa não são estado. "Sessão salva" é uma mensagem para mostrar uma vez;
ela não tem valor atual, e duas mensagens idênticas seguidas são duas mensagens, não uma. Um `StateFlow`
descartaria a segunda como repetição, e entregaria a mensagem velha a toda tela que abrisse depois. **Um
`SharedFlow` é um fluxo quente de eventos**: não tem valor atual, entrega cada emissão aos coletores
presentes, e repete a coletores novos uma quantidade configurável de eventos passados, zero por padrão.

```kotlin
// src/main/kotlin/SharedEvents.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val messages = MutableSharedFlow<String>()
    val early = launch { messages.collect { println("early screen: $it") } }
    delay(10)
    messages.emit("session saved")
    messages.emit("session saved")
    val late = launch { messages.collect { println("late screen: $it") } }
    delay(10)
    messages.emit("goal reached")
    delay(10)
    early.cancel()
    late.cancel()

    val withReplay = MutableSharedFlow<String>(replay = 1)
    withReplay.emit("week exported")
    val opened = launch { withReplay.collect { println("opened later: $it") } }
    delay(10)
    opened.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SharedEventsKt
early screen: session saved
early screen: session saved
early screen: goal reached
late screen: goal reached
opened later: week exported
```

A tela que chegou cedo recebeu as duas mensagens `session saved`, porque um shared flow não descarta
repetições. A tela que chegou tarde as perdeu, por ter chegado depois de emitidas, e recebeu
`goal reached` como a outra. Com `replay = 1`, um coletor que chega depois recebe primeiro o último
evento.

## Qual para quê

**Estado, que sempre tem valor e de que só o mais recente importa: `StateFlow`.** O total da semana, a
lista de sessões, se há um carregamento em andamento. **Eventos, cada um dos quais importa uma vez:
`SharedFlow`**, sem replay, para uma tela que abre depois não mostrar de novo a mensagem de ontem.
Escolher o errado produz os dois bugs clássicos de tela: uma mensagem que aparece duas vezes, ou uma que
nunca aparece.
