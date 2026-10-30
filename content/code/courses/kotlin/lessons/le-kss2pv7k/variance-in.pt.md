---
title: in: um tipo que só consome T
version: 1
---

O caso oposto é um tipo que só recebe `T` e nunca entrega um. Um `Comparator<T>` é assim: recebe dois
`T` e devolve um `Int`. **Um comparador capaz de comparar quaisquer duas `CharSequence` certamente
compara duas `String`**, então um `Comparator<CharSequence>` deveria servir onde se quer um
`Comparator<String>`. Essa é a seta apontando para o outro lado, chamada contravariância, e o `in` a
declara:

```kotlin
// In.kt
interface Sink<in T> {
    fun put(value: T)
}

class Printer : Sink<Any> {
    override fun put(value: Any) = println("got $value")
}

fun deliver(sink: Sink<Int>, minutes: Int) = sink.put(minutes)

fun main() {
    deliver(Printer(), 45)

    val byLength = Comparator<CharSequence> { a, b -> a.length - b.length }
    println(listOf("Kotlin", "Go", "Android").sortedWith(byLength))
}
```

```
ana@vm:~/kt/l12$ kotlinc In.kt -include-runtime -d in.jar && java -jar in.jar
got 45
[Go, Kotlin, Android]
```

`deliver` quer um `Sink<Int>` e recebeu um `Printer`, que é um `Sink<Any>`. Algo que aceita qualquer
valor aceita um `Int`, e o `in` é o que diz isso ao compilador. O `sortedWith` numa lista de `String`
quer um `Comparator<in String>`, e um comparador de `CharSequence` cabe.

## A regra numa linha

| declarado | o tipo | para que lado vai |
|---|---|---|
| `out T` | só produz `T` | um `X<Int>` serve onde se quer um `X<Number>` |
| `in T` | só consome `T` | um `X<Number>` serve onde se quer um `X<Int>` |
| nenhum | produz e consome | um `X<Int>` serve só onde se quer um `X<Int>` |

O mnemônico de Joshua Bloch para a versão do Java é "producer extends, consumer super"; as palavras do
Kotlin o encurtam. **Um tipo de que você lê é `out`; um tipo em que você escreve é `in`.**

## Variância no lugar de uso

Uma classe invariante, como a `MutableList`, ainda pode ser usada de forma covariante num lugar:
`fun total(values: MutableList<out Number>)` aceita uma `MutableList<Int>`, e dentro da função o
`values.add(…)` é recusado, porque por esse parâmetro a lista só é lida. O Java escreve a mesma coisa
como `List<? extends Number>`.
