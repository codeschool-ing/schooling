---
title: when, o switch que é uma expressão
version: 1
---

O `when` é a resposta do Kotlin ao `switch`, e faz mais com menos. **Ele escolhe o primeiro ramo cuja
condição bate, e como o `if` é uma expressão**, então o valor dele pode ser devolvido ou guardado.

```kotlin
// When.kt
fun label(minutes: Int): String = when {
    minutes <= 0 -> "nothing"
    minutes < 30 -> "short"
    minutes < 90 -> "normal"
    else -> "long"
}

fun dayKind(day: Int) = when (day) {
    1, 7 -> "weekend"
    in 2..6 -> "weekday"
    else -> "not a day"
}

fun main() {
    for (m in listOf(0, 20, 45, 120)) println("$m: ${label(m)}")
    println(dayKind(7))
    println(dayKind(3))
    println(dayKind(9))
}
```

```
ana@vm:~/kt/l09$ kotlinc When.kt -include-runtime -d when.jar && java -jar when.jar
0: nothing
20: short
45: normal
120: long
weekend
weekday
not a day
```

Duas formas aparecem. `when { … }` sem nada depois recebe uma condição completa em cada ramo, e
substitui uma corrente de `if … else if`. `when (day) { … }` compara um valor com cada ramo, e um ramo
pode listar vários valores, `1, 7`, ou uma faixa com `in`. **Os ramos são testados em ordem e o
primeiro que bate vence**, e é por isso que `label` testa `< 30` antes de `< 90` sem repetir o limite
de baixo. Não há fall-through nem `break`: cada ramo roda sozinho.

## O `else` é obrigatório quando o `when` é um valor

`label` precisa devolver uma `String` para todo `Int`, e o compilador não consegue saber que as quatro
condições cobrem todo número, então o `else` é obrigatório. Tire-o e o programa não compila, pelo
mesmo motivo de o `if` da lição 3 precisar do `else`.

Há um tipo de valor para o qual o compilador **consegue** saber que todo caso está coberto sem `else`:
um valor cujos casos possíveis são todos conhecidos na compilação. Os enums são o primeiro, na seção
03, e as sealed classes o segundo, que é o assunto desta lição.

## `is` dentro do `when`

Um ramo testa um tipo com `is`, e dentro dele o valor sofre smart cast, como a lição 2 prometeu:

```kotlin
// WhenIs.kt
fun describe(x: Any): String = when (x) {
    is Int -> "a number of minutes: ${x + 0}"
    is String -> "a note of ${x.length} characters"
    is List<*> -> "a list of ${x.size}"
    else -> "something else"
}

fun main() {
    println(describe(45))
    println(describe("read chapter 3"))
    println(describe(listOf(45, 30)))
    println(describe(4.5))
}
```

```
ana@vm:~/kt/l09$ kotlinc WhenIs.kt -include-runtime -d whenis.jar && java -jar whenis.jar
a number of minutes: 45
a note of 14 characters
a list of 2
something else
```

`x.length` compila no ramo de `String` porque o ramo só roda quando `x` é uma `String`. `Any` é o tipo
do qual todo tipo Kotlin é subtipo, e `List<*>` é uma lista de um tipo de item desconhecido, que a
lição 12 explica. Testar um `Any` assim é o último recurso; o resto da lição troca o `Any` por um tipo
que conhece os próprios casos.
