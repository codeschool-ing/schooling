---
title: A lambda no fim da chamada
version: 1
---

`countWhere(week, { it >= 60 })` tem a lambda dentro dos parênteses, entre os outros argumentos. O
Kotlin tem uma regra que muda a cara da maior parte do código Kotlin: **quando o último parâmetro de
uma função é uma função, a lambda pode ser escrita depois do parêntese que fecha.** E quando ela é o
único argumento, os parênteses somem de vez.

```kotlin
// Trailing.kt
fun countWhere(minutes: List<Int>, test: (Int) -> Boolean): Int {
    var count = 0
    for (m in minutes) if (test(m)) count++
    return count
}

fun main() {
    val week = listOf(45, 30, 60, 90, 20)
    println(countWhere(week, { it >= 60 }))
    println(countWhere(week) { it >= 60 })
    println(week.count { it >= 60 })
    repeat(2) { i ->
        println("session ${i + 1}")
    }
}
```

```
ana@vm:~/kt/l04$ kotlinc Trailing.kt -include-runtime -d trailing.jar && java -jar trailing.jar
2
2
2
session 1
session 2
```

As três primeiras linhas imprimem o mesmo número de três jeitos. A terceira usa o `count` da
biblioteca padrão, cujo único argumento é a lambda, então não há parênteses nenhum. **`repeat(2) { … }`
parece um laço que a linguagem oferece, e é uma função comum** da biblioteca padrão,
`repeat(times: Int, action: (Int) -> Unit)`, chamada com uma lambda no fim.

Esse é o propósito da regra. Código escrito em Kotlin parece ter estruturas de controle novas, e a
maioria delas são funções: `repeat`, `use` na aula 13, `launch` na aula 14, `runTest` na aula 18.
O Jetpack Compose, sobre o qual o `android-apps` é construído, é essa regra levada até o fim: uma tela
é uma árvore de chamadas de função, cada uma com uma lambda no fim guardando as chamadas aninhadas
nela.

## Só a última lambda vai para o fim

Uma função com dois parâmetros de função só leva a segunda para o fim. A primeira fica dentro dos
parênteses, e costuma ser mais claro nomear as duas:

```kotlin
// TwoLambdas.kt
fun check(minutes: Int, onLong: () -> Unit, onShort: () -> Unit) {
    if (minutes >= 60) onLong() else onShort()
}

fun main() {
    check(90, { println("long") }) { println("short") }
    check(30, onLong = { println("long") }, onShort = { println("short") })
}
```

```
ana@vm:~/kt/l04$ kotlinc TwoLambdas.kt -include-runtime -d twolambdas.jar && java -jar twolambdas.jar
long
short
```

A primeira chamada é legal e faz quem lê parar para descobrir qual bloco é qual. **Use a forma no fim
quando a lambda é o ponto principal da chamada**, o corpo do laço ou o conteúdo do bloco; use nomes
quando há duas lambdas de mesmo peso.
