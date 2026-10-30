---
title: Classes genéricas, e limites para o que T pode ser
version: 1
---

Uma classe recebe um parâmetro de tipo do mesmo jeito, depois do nome. E muitas vezes `T` não pode ser
qualquer coisa: um ranking precisa de itens comparáveis. **Um limite superior, `T : Comparable<T>`, diz
o que `T` precisa ser**, e dentro da classe o compilador então permite o que esse tipo promete:

```kotlin
// Ranked.kt
class Ranked<T : Comparable<T>>(private val items: List<T>) {
    fun top(): T? = items.maxOrNull()
    fun bottom(): T? = items.minOrNull()
}

fun main() {
    println(Ranked(listOf(45, 90, 30)).top())
    println(Ranked(listOf("Kotlin", "Go", "Android")).bottom())
}
```

```
ana@vm:~/kt/l12$ kotlinc Ranked.kt -include-runtime -d ranked.jar && java -jar ranked.jar
90
Android
```

O `maxOrNull` precisa de itens que consiga comparar, e o limite é o que deixa chamá-lo numa lista de
`T`. `Int` e `String` são ambos `Comparable` consigo mesmos, então os dois rankings funcionam. Um tipo
que não é comparável é recusado na chamada:

```kotlin
// Unranked.kt
class Ranked<T : Comparable<T>>(private val items: List<T>) {
    fun top(): T? = items.maxOrNull()
}

class Session(val course: String, val minutes: Int)

fun main() {
    println(Ranked(listOf(Session("Kotlin", 45))).top())
}
```

```
ana@vm:~/kt/l12$ kotlinc Unranked.kt -include-runtime -d unranked.jar
Unranked.kt:9:13: error: cannot infer type for type parameter 'T'. Specify it explicitly.
    println(Ranked(listOf(Session("Kotlin", 45))).top())
            ^^^^^^
Unranked.kt:9:20: error: argument type mismatch: actual type is 'List<Session>', but 'List<uninferred T (of class Ranked<T : Comparable<T>>)>' was expected.
    println(Ranked(listOf(Session("Kotlin", 45))).top())
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

**O limite moveu o erro para a linha que o causou**: a chamada que passa sessões, e não alguma linha
dentro de `Ranked` que tentou comparar duas delas. É o mesmo movimento que a verificação no `init` da
aula 7 fez, aplicado a tipos.

## Vários limites

`T : Comparable<T>` é um limite. Para mais, uma cláusula `where` depois da assinatura os lista:
`fun <T> longest(items: List<T>) where T : CharSequence, T : Comparable<T>`. Os dois precisam valer,
então a função usa `length` de `CharSequence` e comparação de `Comparable`.

## O limite padrão

Um `T` sem limite escrito tem o limite `Any?`, então ele pode ser `null`. **`<T : Any>` exclui o
`null`**, o que importa quando uma função quer prometer que o resultado nunca é null, ou usar um `T`
como chave de mapa que não pode ser.
