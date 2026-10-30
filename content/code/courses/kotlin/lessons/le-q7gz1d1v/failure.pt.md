---
title: Quando um filho falha, os irmãos são cancelados
version: 1
---

O planejador atualiza três coisas ao mesmo tempo quando abre: sincroniza lembretes, lê o calendário e
exporta a semana. Se ler o calendário falha, **o que deve acontecer com as outras duas?** Na
concorrência estruturada a resposta é fixa: a exceção do filho que falhou sobe até o escopo, o escopo
cancela todo outro filho e, quando todos terminam, o escopo lança a exceção para quem o chamou.

```kotlin
// src/main/kotlin/Failure.kt
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    try {
        coroutineScope {
            launch {
                try {
                    delay(500)
                    println("reminders synced")
                } finally {
                    println("reminder sync cancelled")
                }
            }
            launch {
                delay(200)
                throw IllegalStateException("calendar unreachable")
            }
            launch {
                try {
                    delay(1000)
                    println("week exported")
                } finally {
                    println("export cancelled")
                }
            }
        }
    } catch (e: IllegalStateException) {
        println("refresh failed: ${e.message}")
    }
    println("planner still running")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FailureKt
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

Aos 200 milissegundos o filho do calendário lançou exceção. O escopo cancelou os outros dois, cujos
blocos `finally` rodaram, e só então o `coroutineScope` relançou `calendar unreachable` para o `main`,
que a pegou como uma exceção de qualquer chamada de função. **Nenhum irmão terminou o trabalho, e
nenhum foi esquecido**: a atualização como um todo falhou, e o código que a pediu foi avisado.

## Por que cancelar os irmãos

Porque o resultado para o qual eles contribuíam não pode mais ser montado. As três atualizações são
uma operação só, "abrir o planejador", e depois que uma parte falhou, o resto é na melhor das hipóteses
trabalho desperdiçado e, na pior, metade de uma atualização gravada em disco. O par de `async` da lição
14 se comportava do mesmo jeito: se uma carga lança exceção, a outra é cancelada e o `await` relança.

Quando as partes são de fato independentes, de modo que uma falhar deve deixar as outras em paz, o
escopo precisa dizer isso, e esse é o assunto da próxima seção.
