---
title: Funções genéricas: uma função para todo tipo
version: 1
---

`List<Int>` aparece desde a lição 3, e os sinais de menor e maior ficaram sem explicação. **Eles são um
parâmetro de tipo**: `List` é escrita uma vez, para um tipo a ser nomeado depois, e `List<Int>` e
`List<String>` são dois usos dela. Funções também têm parâmetros de tipo:

```kotlin
// Generic.kt
fun <T> firstOrDefault(items: List<T>, default: T): T =
    if (items.isEmpty()) default else items[0]

fun <T> List<T>.second(): T? = if (size >= 2) this[1] else null

fun main() {
    println(firstOrDefault(listOf(45, 30), 0))
    println(firstOrDefault(emptyList<String>(), "none"))
    println(listOf("Kotlin", "Android").second())
    val n: Int = firstOrDefault(listOf(45), 0)
    println(n + 1)
}
```

```
ana@vm:~/kt/l12$ kotlinc Generic.kt -include-runtime -d generic.jar && java -jar generic.jar
45
none
Android
46
```

`fun <T>` declara um parâmetro de tipo `T` antes do nome da função, e `T` é usado depois como qualquer
tipo nos parâmetros e no resultado. **Em cada chamada, o compilador descobre o que `T` é pelos
argumentos**: um `Int` na primeira chamada, uma `String` na segunda. O resultado tem esse tipo, e é por
isso que `n + 1` compila: `firstOrDefault` devolveu um `Int`, não um objeto genérico que precisaria de
cast.

Esse é o propósito dos genéricos. Sem eles, `firstOrDefault` receberia `List<Any>` e devolveria `Any`,
e todo chamador faria cast do resultado, torcendo para estar certo. **Com eles, o tipo que entrou é o
tipo que sai, e o compilador verifica.**

## Nomeando o tipo você mesmo

`emptyList<String>()` nomeia `T` explicitamente, porque uma lista vazia não tem de onde inferir. Você
nomeia em qualquer chamada, e então o compilador verifica os argumentos contra ele:

```kotlin
// Explicit.kt
fun <T> firstOrDefault(items: List<T>, default: T): T =
    if (items.isEmpty()) default else items[0]

fun main() {
    println(firstOrDefault<Int>(listOf(45), "none"))
}
```

```
ana@vm:~/kt/l12$ kotlinc Explicit.kt -include-runtime -d explicit.jar
Explicit.kt:6:45: error: argument type mismatch: actual type is 'String', but 'Int' was expected.
    println(firstOrDefault<Int>(listOf(45), "none"))
                                            ^^^^^^
```

Com `T` fixado em `Int`, um padrão `String` não cabe. Deixado para inferir, o compilador procuraria um
tipo a que tanto um `Int` quanto uma `String` pertencem e acharia um, um supertipo comum, que raramente
é o que alguém quis dizer. **Quando a inferência escolhe um tipo surpreendente, nomear o `T` transforma
a surpresa numa mensagem de erro.**
