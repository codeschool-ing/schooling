---
title: async e await, para um resultado de cada
version: 1
---

O `launch` é para trabalho cujo resultado ninguém precisa. **O `async` inicia uma corrotina que produz
um valor, e devolve um `Deferred`**, uma promessa desse valor; o `await()` suspende até ele ficar pronto
e o devolve. Duas cargas que não dependem uma da outra podem então rodar ao mesmo tempo.

O `Async.kt` não declara `loadWeek` nem `loadGoal` próprios: ele usa os do `Suspend.kt`. **Todo arquivo
em `src/main/kotlin` é compilado junto, num único espaço de nomes**, então uma função de nível superior
num arquivo é visível em todos os outros, e declarar um segundo `loadWeek` em outro arquivo não
compilaria: o compilador chama isso de sobrecargas conflitantes. Os programas das lições 14 a 17 dividem
este projeto, então cada arquivo novo usa nomes próprios, ou reaproveita o que um arquivo anterior
declarou.

```kotlin
// src/main/kotlin/Async.kt
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlin.time.measureTime

fun main() = runBlocking {
    val oneByOne = measureTime {
        val week = loadWeek()
        val goal = loadGoal()
        println("${week.sum()} of $goal min")
    }
    println("one after the other: ${oneByOne.inWholeMilliseconds / 100 * 100} ms or so")

    val together = measureTime {
        val week = async { loadWeek() }
        val goal = async { loadGoal() }
        println("${week.await().sum()} of ${goal.await()} min")
    }
    println("side by side: ${together.inWholeMilliseconds / 100 * 100} ms or so")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=AsyncKt
loading the week
week loaded
135 of 300 min
one after the other: 500 ms or so
loading the week
week loaded
135 of 300 min
side by side: 300 ms or so
```

`loading the week` e `week loaded` são impressos pelo `loadWeek` do `Suspend.kt`, uma vez por rodada.
O `measureTime` da biblioteca padrão cronometra um bloco. O programa arredonda para baixo na centena de
milissegundos, porque o número exato varia alguns milissegundos entre execuções e as centenas é que
importam. **Uma depois da outra, as duas cargas levaram a soma, 300 e 200; lado a lado, levaram a mais
longa das duas**, porque os dois delays corriam ao mesmo tempo. A resposta é a mesma nas duas: só a
espera se sobrepôs.

## Inicie as duas, depois espere

A ordem das linhas importa. O `async` começa o trabalho na hora, então as duas cargas já estão rodando
antes do primeiro `await`. Escrever `async { loadWeek() }.await()` e depois `async { loadGoal() }.await()`
iniciaria a segunda só depois de a primeira terminar, e seria tão lento quanto a versão sequencial, com
mais palavras. **Inicie tudo o que pode rodar ao mesmo tempo, depois espere os resultados.**

## Quando uma carga falha

Se `loadWeek` lança uma exceção, o `await()` lança a mesma exceção em quem chama, e o outro `async` é
cancelado: um resultado que falhou quer dizer que o resultado combinado não pode ser montado, então o
irmão dele para de gastar trabalho. Isso é concorrência estruturada de novo, e a lição 15 mostra
acontecendo.
