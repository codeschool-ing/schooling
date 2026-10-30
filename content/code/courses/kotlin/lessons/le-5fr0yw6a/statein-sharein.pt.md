---
title: stateIn e shareIn: tornando quente um flow frio
version: 1
---

Um flow frio roda o produtor uma vez por coletor. Duas telas coletando o mesmo registro o abririam duas
vezes. **O `shareIn` roda um flow frio uma vez, num escopo que você lhe dá, e divide os valores com todo
coletor**; o `stateIn` faz o mesmo e guarda o valor mais recente como um `StateFlow`.

```kotlin
// src/main/kotlin/ShareIn.kt
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val log = flow {
        println("  opening the log")
        for (m in listOf(45, 30, 60)) {
            delay(100)
            emit(m)
        }
    }
    val shared = log.shareIn(this, SharingStarted.Eagerly, replay = 3)
    launch { shared.collect { println("screen A got $it") } }
    launch { shared.collect { println("screen B got $it") } }
    delay(500)
    coroutineContext.cancelChildren()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ShareInKt
  opening the log
screen A got 45
screen B got 45
screen A got 30
screen B got 30
screen A got 60
screen B got 60
```

`opening the log` foi impresso uma vez, e as duas telas receberam os três valores. A divisão roda numa
corrotina do escopo passado, aqui o do `runBlocking`, e **continua rodando até esse escopo ser
cancelado**: o `cancelChildren()` no fim a para, junto com os dois coletores, para o programa conseguir
terminar. É a estrutura da lição 15 fazendo o trabalho dela: o produtor compartilhado pertence a um
escopo, e não sobrevive a ele.

## Quando a divisão começa e para

O `SharingStarted` decide quando o produtor roda:

| política | o produtor roda |
|---|---|
| `Eagerly` | desde a chamada do `shareIn`, até o escopo acabar |
| `Lazily` | desde o primeiro coletor, até o escopo acabar |
| `WhileSubscribed(5000)` | enquanto alguém coleta, e por cinco segundos depois de o último sair |

O `WhileSubscribed(5000)` é o que o `android-apps` usa para estado vindo de um banco de dados ou da rede:
o trabalho para quando ninguém está olhando, e os cinco segundos cobrem uma tela girando, o que no
Android a destrói e a reconstrói e, sem isso, reiniciaria o produtor a cada vez.
