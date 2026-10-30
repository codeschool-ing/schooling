---
title: Expressões object: um objeto feito na hora
version: 1
---

Uma declaração `object` nomeia uma instância única para o programa inteiro. **Uma expressão object
cria um objeto novo, sem nome, bem onde é escrita**, em geral para implementar uma interface uma vez
sem declarar uma classe para isso. É a versão do Kotlin da classe anônima do Java.

```kotlin
// Anonymous.kt
fun main() {
    val byLength = object : Comparator<String> {
        override fun compare(a: String, b: String): Int = a.length - b.length
    }
    println(listOf("Kotlin", "Go", "Android").sortedWith(byLength))

    var clicks = 0
    val counter = object {
        fun click() {
            clicks++
        }
    }
    counter.click()
    counter.click()
    println(clicks)
}
```

```
ana@vm:~/kt/l10$ kotlinc Anonymous.kt -include-runtime -d anonymous.jar && java -jar anonymous.jar
[Go, Kotlin, Android]
2
```

`object : Comparator<String> { … }` monta um objeto que implementa a interface `Comparator` do Java,
com o único método dela escrito no lugar; `override` diz que o método cumpre a interface, o que a lição
11 cobre. O `sortedWith` o usa para ordenar os cursos pelo comprimento.

O segundo objeto não implementa nada e tem uma função própria. Como as lambdas da lição 4, **ele lê e
muda as variáveis em volta dele**: `clicks` pertence ao `main`, e a função do objeto o incrementa.

## Uma lambda costuma ser mais curta

O `Comparator` tem um único método abstrato, então o Kotlin aceita uma lambda no lugar dele, e a
biblioteca padrão tem ajudantes que montam um:

```kotlin
// Shorter.kt
fun main() {
    val courses = listOf("Kotlin", "Go", "Android")
    println(courses.sortedWith { a, b -> a.length - b.length })
    println(courses.sortedWith(compareBy { it.length }))
    println(courses.sortedBy { it.length })
}
```

```
ana@vm:~/kt/l10$ kotlinc Shorter.kt -include-runtime -d shorter.jar && java -jar shorter.jar
[Go, Kotlin, Android]
[Go, Kotlin, Android]
[Go, Kotlin, Android]
```

As três linhas imprimem a mesma ordem. **Uma expressão object se justifica quando a interface tem mais
de um método para implementar, ou quando o objeto precisa de estado próprio**; para um método, a lambda
diz o mesmo numa linha. Interfaces Java com um método ganham essa conversão automaticamente, e uma
interface Kotlin ganha quando é declarada como `fun interface`.
