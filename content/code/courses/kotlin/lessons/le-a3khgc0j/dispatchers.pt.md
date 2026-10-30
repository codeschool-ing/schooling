---
title: Dispatchers: em quais threads uma corrotina roda
version: 1
---

Uma corrotina não é uma thread. Ela roda numa, e um **dispatcher** decide qual. As corrotinas até aqui
rodaram todas na thread do próprio `main`, porque o `runBlocking` usa a thread que o chamou. A
biblioteca tem três dispatchers para o resto:

| dispatcher | as threads dele | para |
|---|---|---|
| `Dispatchers.Default` | tantas quantos núcleos o processador tem | trabalho que ocupa o processador: ordenar, interpretar, calcular |
| `Dispatchers.IO` | um conjunto maior, 64 por padrão | trabalho que espera: arquivos, rede, banco de dados |
| `Dispatchers.Main` | a única thread que desenha a tela | só no Android, Swing ou JavaFX; não existe num programa JVM simples |

**`withContext(dispatcher) { … }` roda um bloco em outro dispatcher e devolve o resultado**, então uma
função consegue tirar o próprio trabalho pesado da thread de quem a chamou:

```kotlin
// src/main/kotlin/Dispatch.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File

fun where() = Thread.currentThread().name.substringBefore(" @")

suspend fun readWeek(path: String): List<Int> = withContext(Dispatchers.IO) {
    println("reading on ${where()}")
    File(path).readLines().map { it.trim().toInt() }
}

suspend fun summarise(minutes: List<Int>): String = withContext(Dispatchers.Default) {
    println("summing on ${where()}")
    "${minutes.size} sessions, ${minutes.sum()} min"
}

fun main() = runBlocking {
    File("week.txt").writeText("45\n30\n60\n")
    println("main on ${where()}")
    val week = readWeek("week.txt")
    println(summarise(week))
    println("back on ${where()}")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=DispatchKt
main on main
reading on DefaultDispatcher-worker-1
summing on DefaultDispatcher-worker-1
3 sessions, 135 min
back on main
```

O `main` rodou na thread chamada `main`, o arquivo foi lido num trabalhador do conjunto de IO, a soma
rodou num trabalhador do conjunto Default, e depois de cada `withContext` o código estava **de volta na
thread do `main`**, porque o `withContext` volta ao dispatcher de onde foi chamado. Os números dos
trabalhadores dependem de qual thread estava livre, e os seus podem ser outros.

## Por que isso importa no Android

No Android, o `Dispatchers.Main` é a thread que desenha a tela e trata os toques, e qualquer coisa lenta
nela congela o app; depois de cinco segundos o sistema oferece fechá-lo. O padrão que o `android-apps`
usa em todo lugar é este: **uma tela chama uma função suspensa a partir do `Main`, e a função leva o
próprio trabalho de arquivo, rede ou banco de dados para o `IO` com `withContext`**, então quem chama
nunca precisa saber.

Os dispatchers IO e Default dividem threads por baixo, e é por isso que o nome de um trabalhador diz
`DefaultDispatcher` mesmo quando ele faz trabalho de IO: os conjuntos são dois limites sobre um único
grupo de threads, não dois grupos separados.
