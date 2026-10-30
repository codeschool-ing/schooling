---
title: Um escopo: nenhuma corrotina sobrevive ao trabalho a que pertence
version: 1
---

A aula 14 terminou com uma regra: o `runBlocking` espera toda corrotina iniciada dentro dele. **Essa
regra é toda a concorrência estruturada**: toda corrotina é iniciada dentro de um escopo, o escopo não
termina até todas terminarem, e assim nenhuma corrotina é esquecida, rodando depois de o código que a
iniciou já ter seguido em frente.

`coroutineScope { … }` cria um escopo assim dentro de uma função suspensa. É assim que uma função que
inicia corrotinas cumpre a promessa de que, quando retorna, terminou de verdade:

```kotlin
// src/main/kotlin/Scope.kt
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

private suspend fun fetchCourse(name: String, ms: Long): String {
    delay(ms)
    println("  loaded $name")
    return name
}

suspend fun loadPlan(): List<String> = coroutineScope {
    val kotlin = async { fetchCourse("Kotlin", 300) }
    val android = async { fetchCourse("Android", 100) }
    listOf(kotlin.await(), android.await())
}

fun main() = runBlocking {
    println("loading")
    val plan = loadPlan()
    println("plan: $plan")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ScopeKt
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

`loadPlan` inicia duas corrotinas e só retorna quando as duas terminam; quem a chama não tem como saber
que ela usou corrotinas. **Vista de fora, uma função com um `coroutineScope` dentro é só uma função
`suspend` que demora um pouco.** É isso que torna a concorrência combinável: `loadPlan` é chamada de
qualquer lugar onde uma função suspensa é, e nada do que ela iniciou vaza.

`fetchCourse` é `private`, porque as aulas 14 a 17 dividem um projeto e um nome de nível superior
precisa ser único nele; o `Async.kt` da aula 14 mostrou o que acontece caso contrário.

## A árvore

Toda corrotina iniciada num escopo vira **filha** do job daquele escopo, e os jobs formam uma árvore:
`runBlocking` na raiz, `coroutineScope` abaixo, os dois `async` abaixo dele. A árvore é o que faz as
próximas três seções funcionarem. **O cancelamento desce por ela**, de um pai para todo filho; **a falha
sobe por ela**, de um filho para o pai, que então cancela os outros filhos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l15-tree\" aria-label=\"Uma árvore de jobs. runBlocking na raiz, coroutineScope abaixo dela, e três filhos abaixo: sincronizar lembretes, ler calendário, exportar semana. O filho ler calendário falha. Uma seta leva a falha dele até o coroutineScope. Setas do coroutineScope levam o cancelamento até os outros dois filhos. Então o coroutineScope lança a falha para o runBlocking. Uma nota: a falha sobe, o cancelamento desce.\"><defs><marker id=\"l15-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-tree-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"280\" y=\"14\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">runBlocking</text><rect x=\"270\" y=\"84\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">coroutineScope</text><path d=\"M360 50 L360 82\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sincronizar lembretes</text><rect x=\"280\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ler calendário</text><rect x=\"520\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exportar semana</text><path d=\"M360 120 L120 168\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360 120 L600 168\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M345 168 L345 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-tree-ah-amber)\"></path><text x=\"300\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">falha</text><path d=\"M330 122 L150 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l15-tree-ah-paper-dim)\"></path><path d=\"M392 122 L570 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l15-tree-ah-paper-dim)\"></path><text x=\"200\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelado</text><text x=\"520\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelado</text><path d=\"M378 82 L378 52\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-tree-ah-amber)\"></path><text x=\"470\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">relançada para quem chamou</text><text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a falha sobe, o cancelamento desce</text></svg>", "caption": "Corrotinas formam uma árvore de jobs: uma falha sobe até o escopo, que cancela os outros filhos e depois relança."}
```
