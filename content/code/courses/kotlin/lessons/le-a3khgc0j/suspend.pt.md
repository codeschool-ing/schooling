---
title: suspend: uma função que pode pausar
version: 1
---

Um planejador de estudos num celular carrega a semana de um arquivo ou de um servidor, e carregar leva
tempo. Se o código espera por isso na thread que desenha a tela, a tela congela. As respostas antigas
eram uma segunda thread, que é cara, ou um callback, que transforma uma operação de três passos em três
blocos aninhados. **Uma função suspensa pode pausar no meio, liberar a thread para outro trabalho e
retomar de onde parou**, enquanto o código se lê de cima para baixo como código comum.

```kotlin
// src/main/kotlin/Suspend.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

suspend fun loadWeek(): List<Int> {
    println("loading the week")
    delay(300)
    println("week loaded")
    return listOf(45, 30, 60)
}

suspend fun loadGoal(): Int {
    delay(200)
    return 300
}

fun main() = runBlocking {
    val week = loadWeek()
    val goal = loadGoal()
    println("${week.sum()} of $goal min")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SuspendKt
loading the week
week loaded
135 of 300 min
```

O `suspend` marca `loadWeek` como uma função que pode pausar. O `delay(300)` é a pausa: ele suspende a
corrotina por 300 milissegundos **sem bloquear a thread**, que fica livre para rodar qualquer outra
coisa nesse meio-tempo. Quando o tempo acaba, `loadWeek` retoma na linha depois do `delay`, com as
variáveis locais intactas. Nada aqui roda ao mesmo tempo que outra coisa ainda; as duas cargas rodaram
uma depois da outra, e a seção 05 as faz se sobrepor.

## Só a partir de uma corrotina

Uma função suspensa só é chamada por outra função suspensa, ou por um construtor de corrotina como o
`runBlocking`. Chamá-la de código comum é recusado:

```kotlin
// src/main/kotlin/NotSuspend.kt
import kotlinx.coroutines.delay

fun main() {
    delay(300)
    println("done")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=NotSuspendKt
e: file:///home/ana/kt/planner/src/main/kotlin/NotSuspend.kt:5:5 Suspend function 'suspend fun delay(timeMillis: Long): Unit' can only be called from a coroutine or another suspend function.

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Kotlin compiler: ILLEGAL_SUSPEND_FUNCTION_CALL
       Kotlin compiler error
         Suspend function 'suspend fun delay(timeMillis: Long): Unit' can only be called from a coroutine or another suspend function.
         Location: /home/ana/kt/planner/src/main/kotlin/NotSuspend.kt:5

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

Apague o `NotSuspend.kt` depois de ver a mensagem: **um arquivo que não compila impede o projeto
inteiro de compilar**, inclusive todos os outros programas dele.

O motivo é mecânico. **O compilador reescreve toda função `suspend`** para ela poder ser parada em cada
ponto de suspensão e continuada depois: ela ganha um parâmetro extra escondido, uma continuação, que
guarda onde ela estava e quais eram as variáveis. Uma função comum não tem continuação para passar,
então não consegue chamar uma. O `runBlocking` é a ponte: ele inicia uma corrotina e bloqueia a thread
atual até ela terminar, o que é certo para o `main` e para testes, e errado em qualquer outro lugar,
porque bloquear uma thread é justamente o que tudo isso existe para evitar.

## `delay` não é `Thread.sleep`

O `Thread.sleep(300)` para a thread por 300 milissegundos, e nada mais a usa. O `delay(300)` para só a
corrotina. A diferença é invisível com uma corrotina, e é todo o propósito com muitas, que a seção 07
mede.
