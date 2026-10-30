---
title: Perguntas de uma resposta: somas, contagens, extremos
version: 1
---

`map` e `filter` devolvem listas. Muitas perguntas sobre uma lista querem um valor só: quantos,
quanto no total, qual é o mais longo, existe algum. A biblioteca padrão tem uma função para cada uma,
e **conhecer os nomes delas é a maior parte de escrever Kotlin rápido**.

```kotlin
// Aggregates.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60, "Go" to 20)

    println(sessions.sumOf { it.second })
    println(sessions.count { it.first == "Kotlin" })
    println(sessions.any { it.second > 90 })
    println(sessions.all { it.second >= 20 })
    println(sessions.none { it.first == "Swift" })
    println(sessions.maxBy { it.second })
    println(sessions.minOf { it.second })
    println(sessions.sortedByDescending { it.second }.take(2))
    println(sessions.map { it.first }.distinct())
    println(sessions.firstOrNull { it.first == "Swift" })
}
```

```
ana@vm:~/kt/l05$ kotlinc Aggregates.kt -include-runtime -d aggregates.jar && java -jar aggregates.jar
155
2
false
true
true
(Kotlin, 60)
20
[(Kotlin, 60), (Kotlin, 45)]
[Kotlin, Android, Go]
null
```

| função | responde |
|---|---|
| `sumOf { … }` | o total de um número tirado de cada item |
| `count { … }` | quantos itens passam no teste |
| `any`, `all`, `none` | se pelo menos um, todos ou nenhum item passa |
| `maxBy { … }`, `minBy { … }` | o item com o maior ou o menor valor |
| `maxOf { … }`, `minOf { … }` | esse maior ou menor valor em si |
| `sortedBy { … }`, `sortedByDescending { … }` | uma lista nova nessa ordem |
| `take(n)`, `drop(n)` | os primeiros `n` itens, ou todos menos eles |
| `distinct()` | os itens sem repetição, mantendo a primeira ocorrência |
| `first { … }`, `firstOrNull { … }` | o primeiro item que passa |

## `By` e `Of`

Os pares `maxBy`/`maxOf` e `minBy`/`minOf` se confundem fácil, e a saída mostra a diferença. **O
`maxBy` devolve um item; o `maxOf` devolve um valor calculado a partir de um.** A sessão mais longa é
`(Kotlin, 60)`, e a menor duração é `20`.

## As que falham numa lista vazia

`first`, `maxBy` e `minBy` não têm resposta para uma lista vazia, e lançam `NoSuchElementException`
em vez de inventar uma. Cada uma tem uma irmã `OrNull`, que devolve `null` no lugar e por isso devolve
um tipo anulável:

```kotlin
// Empty.kt
fun main() {
    val none = listOf<Pair<String, Int>>()
    println(none.sumOf { it.second })
    println(none.maxByOrNull { it.second })
    println(none.maxBy { it.second })
}
```

```
ana@vm:~/kt/l05$ kotlinc Empty.kt -include-runtime -d empty.jar && java -jar empty.jar
0
null
Exception in thread "main" java.util.NoSuchElementException
	at EmptyKt.main(Empty.kt:25)
	at EmptyKt.main(Empty.kt)
```

A soma de nada é 0, que é uma resposta de verdade. O mais longo de nada é `null` na forma `OrNull`, e
uma exceção sem ela. **Use a forma `OrNull` sempre que a lista puder estar vazia**, o que, para as
sessões de uma estudante numa semana nova, é a primeira coisa que acontece, e responda o `null` com as
ferramentas da aula 2.
