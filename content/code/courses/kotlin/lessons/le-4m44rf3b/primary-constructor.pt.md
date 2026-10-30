---
title: Uma classe e o construtor primário dela
version: 1
---

Até aqui uma sessão de estudo era um `Pair` de um curso e um número, e `it.second` não dizia nada
sobre o que o número era. **Uma classe dá nomes próprios aos dados do planejador.** Em Kotlin a
classe útil mais curta tem uma linha:

```kotlin
// Course.kt
class Course(val name: String, val weeklyGoal: Int)

fun main() {
    val kotlin = Course("Kotlin", 300)
    println(kotlin.name)
    println(kotlin.weeklyGoal)
    println(kotlin)
}
```

```
ana@vm:~/kt/l07$ kotlinc Course.kt -include-runtime -d course.jar && java -jar course.jar
Kotlin
300
Course@677327b6
```

Os parênteses depois do nome da classe são o **construtor primário** dela, e o `val` na frente de
cada parâmetro o torna também uma propriedade: uma linha declara os parâmetros, os campos que os
guardam, os getters que os leem e o código que copia um para o outro. A classe Java que faz o mesmo
tem umas quinze linhas. Não há `new`: uma classe é construída chamando-a como uma função,
`Course("Kotlin", 300)`.

A última linha imprimiu `Course@` e um número, que é o texto padrão da JVM para um objeto: a classe
dele e um hash code. As data classes da aula 8 trocam isso por algo legível.

## `val`, `var`, ou nenhum

Cada parâmetro do construtor pode ser uma de três coisas:

```kotlin
// Session.kt
class Session(val course: String, val minutes: Int, var done: Boolean = false, date: String) {
    val label = "$date $course"
}

fun main() {
    val s = Session("Kotlin", 45, date = "2026-11-02")
    println(s.label)
    println(s.done)
    s.done = true
    println(s.done)
}
```

```
ana@vm:~/kt/l07$ kotlinc Session.kt -include-runtime -d session.jar && java -jar session.jar
2026-11-02 Kotlin
false
true
```

| parâmetro | vira |
|---|---|
| `val course: String` | uma propriedade somente leitura |
| `var done: Boolean = false` | uma propriedade que muda, com um padrão como qualquer parâmetro de função |
| `date: String` | um parâmetro simples: usado enquanto o objeto é montado, e depois some |

`date` é usado para calcular `label` e não é guardado; `s.date` não compilaria. **Marque um parâmetro
como `val` só se o objeto precisa dele depois da construção.** E, como em todo este curso, `val` até
algo precisar mudar: o curso e a duração de uma sessão ficam fixos quando ela é planejada, e se ela
foi feita é a única coisa que se mexe.

## Argumentos nomeados e padrão valem aqui também

Um construtor é uma função, então a aula 3 vale inteira: padrões, nomes e a vírgula no fim. A
chamada acima nomeia `date` porque ele vem depois de um parâmetro com padrão, exatamente o caso que a
aula 3 mandou nomear.
