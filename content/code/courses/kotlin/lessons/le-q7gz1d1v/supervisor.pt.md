---
title: supervisorScope, para filhos que falham sozinhos
version: 1
---

Algum trabalho é um conjunto de tarefas independentes: três notificações para enviar, cinco arquivos
para subir. Uma falhar não diz nada sobre as outras. **O `supervisorScope` é um escopo em que a falha
de um filho não cancela os irmãos nem o escopo**; cada filho dá certo ou errado sozinho, e o escopo
ainda espera todos eles.

```kotlin
// src/main/kotlin/Supervisor.kt
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.supervisorScope

fun main() = runBlocking {
    val report = CoroutineExceptionHandler { _, e -> println("a task failed: ${e.message}") }
    supervisorScope {
        launch(report) {
            delay(100)
            println("reminders synced")
        }
        launch(report) {
            delay(50)
            throw IllegalStateException("calendar unreachable")
        }
        launch(report) {
            delay(150)
            println("week exported")
        }
    }
    println("all three tasks settled")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SupervisorKt
e: file:///home/ana/kt/planner/src/main/kotlin/Global.kt:9:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Swallow.kt:7:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Timeout.kt:13:1 Conflicting overloads:
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Kotlin compiler: CONFLICTING_OVERLOADS
       Kotlin compiler error
         Conflicting overloads:
         fun main(): Any
         Location: /home/ana/kt/planner/src/main/kotlin/Global.kt:9

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

A tarefa do calendário falhou aos 50 milissegundos e as outras duas terminaram como se nada tivesse
acontecido. **Num escopo supervisor, cada filho precisa lidar com a própria falha**, porque o escopo não
a propaga: o `CoroutineExceptionHandler` é um tratador de último recurso para a exceção de um `launch`
que ninguém mais pegou, e aqui ele relata a falha em vez de deixá-la sumir ou derrubar o programa.

## Qual usar

**`coroutineScope` quando os filhos são partes de um resultado; `supervisorScope` quando são tarefas
separadas que calham de rodar ao mesmo tempo.** Carregar a semana e a meta para desenhar uma tela é o
primeiro caso: sem qualquer uma delas, não há tela. Enviar um lembrete a cada um de três aparelhos é o
segundo.

No Android, o escopo que roda o trabalho de uma tela, o `viewModelScope` do `android-apps`, é um escopo
supervisor por esse motivo: uma requisição que falhou numa tela não deve cancelar todo o resto que
aquela tela está fazendo.
