---
title: Desestruturação, e por que ela é por posição
version: 1
---

A aula 5 usou `val (long, short) = sessions.partition { … }` e `{ (_, list) -> … }` e prometeu uma
explicação. **A desestruturação desmonta um objeto em vários nomes numa declaração só**, e para uma
data class ela funciona de fábrica:

```kotlin
// Destructure.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val s = Session("Kotlin", 45, done = true)
    val (course, minutes) = s
    println("$course $minutes")

    val (_, m, done) = s
    println("$m $done")

    val sessions = listOf(Session("Kotlin", 45), Session("Android", 30))
    for ((c, min) in sessions) println("$c: $min")
    println(sessions.map { (c, min) -> "$c=$min" })
}
```

```
ana@vm:~/kt/l08$ kotlinc Destructure.kt -include-runtime -d destructure.jar && java -jar destructure.jar
Kotlin 45
45 true
Kotlin: 45
Android: 30
[Kotlin=45, Android=30]
```

`val (course, minutes) = s` é `val course = s.component1()` e `val minutes = s.component2()`. A data
class gerou um `componentN` por propriedade do construtor, **na ordem em que foram declaradas**, e a
desestruturação os chama nessa ordem. Nomes que você não quer ficam de fora no fim, ou são pulados com
`_` em qualquer lugar. A mesma sintaxe funciona num laço `for` e nos parâmetros de uma lambda, que é o
que a aula 5 usou: `Pair` e as entradas de mapa também têm `component1` e `component2`.

## Os nomes que você escreve não importam

Esta é a parte que surpreende, e é o motivo de usar a desestruturação com cuidado:

```kotlin
// Swap.kt
data class Note(val title: String, val course: String)

fun main() {
    val (course, title) = Note("Read chapter 3", "Kotlin")
    println("course=$course title=$title")
}
```

```
ana@vm:~/kt/l08$ kotlinc Swap.kt -include-runtime -d swap.jar && java -jar swap.jar
course=Read chapter 3 title=Kotlin
```

Os nomes à esquerda são nomes locais novos, escolhidos por quem escreve aquela linha. **Eles são
ligados às propriedades por posição, não por nome**, então `course` recebeu o título. Os dois são
`String`, então o compilador não teve motivo para reclamar, e o programa imprimiu uma frase errada. O
mesmo acontece com toda desestruturação de um código quando alguém reordena as propriedades de uma
data class.

Então: desestruture onde a ordem é óbvia e estável, um `Pair`, uma entrada de mapa, uma classe de duas
propriedades que vai continuar assim, e **leia propriedades pelo nome, `s.course`, em todo o resto**.
Uma ligação por posição é o tipo de conexão que continua funcionando depois de já ter começado a estar
errada.
