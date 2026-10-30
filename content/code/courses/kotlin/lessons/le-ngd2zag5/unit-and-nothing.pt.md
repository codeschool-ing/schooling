---
title: Unit e Nothing, os dois tipos de retorno sem valor
version: 1
---

Toda função Kotlin devolve alguma coisa, inclusive as que parecem não devolver nada. Dois tipos fazem
isso funcionar, e o segundo deles explica um pedaço da lição 2 que ficou sem explicação: como
`?: return` e `?: throw` ficam onde deveria haver um valor.

## `Unit`: terminou, nada a relatar

Uma função sem tipo de retorno escrito, e com corpo de bloco, devolve `Unit`. `Unit` é um tipo com
exatamente um valor, também chamado `Unit`, então devolvê-lo diz "esta função terminou" e não carrega
informação. Ele faz o papel do `void` do Java, com uma diferença: **é um valor de verdade**, que você
guarda e imprime.

```kotlin
// UnitNothing.kt
fun log(message: String) {
    println("> $message")
}

fun fail(message: String): Nothing = throw IllegalStateException(message)

fun minutesFrom(input: String): Int = input.toIntOrNull() ?: fail("not a number: $input")

fun main() {
    val result = log("planned 45 min")
    println(result)
    println(minutesFrom("45"))
    println(minutesFrom("forty"))
}
```

```
ana@vm:~/kt/l03$ kotlinc UnitNothing.kt -include-runtime -d unitnothing.jar && java -jar unitnothing.jar
> planned 45 min
kotlin.Unit
45
Exception in thread "main" java.lang.IllegalStateException: not a number: forty
	at UnitNothingKt.fail(UnitNothing.kt:6)
	at UnitNothingKt.minutesFrom(UnitNothing.kt:8)
	at UnitNothingKt.main(UnitNothing.kt:14)
	at UnitNothingKt.main(UnitNothing.kt)
```

`println(result)` imprimiu `kotlin.Unit`, o nome do único valor. Que `Unit` seja um valor importa mais
do que parece quando funções passam a ser valores, na lição 4: uma função "que não devolve nada" é uma
função que devolve `Unit`, e ela cabe em qualquer lugar onde se espera uma função que devolve algum
tipo, sem caso especial.

## `Nothing`: nunca termina

`fail` é declarada como devolvendo `Nothing`. **`Nothing` é o tipo sem valor nenhum**, então uma função
que o devolve nunca retorna normalmente: lança uma exceção, ou fica em laço para sempre. O compilador
sabe disso, e usa.

Como `Nothing` não tem valores, o compilador o trata como compatível com qualquer tipo: não existe
valor dele que possa ser do tipo errado. É por isso que `minutesFrom` compila. O `?:` precisa de um
`Int` à direita, e `fail(…)` é `Nothing`, que cabe. **`throw` e `return` também são expressões do tipo
`Nothing`**, e essa é toda a explicação do `?: return` e do `?: throw` da lição 2.

O compilador também sabe que o código depois de uma chamada a `fail` nunca roda, e avisa que ele é
inalcançável. Um ajudante como `fail` vale a pena justamente por isso: um lugar que monta a mensagem e
a exceção, e todo chamador continua sendo verificado como se ele devolvesse o valor que devia.

A biblioteca padrão já tem dois ajudantes assim. `error(message)` lança `IllegalStateException`, e
`TODO()` lança `NotImplementedError`; os dois são declarados devolvendo `Nothing`. Vale conhecer o
`TODO()` em especial, porque ele deixa uma função escrita pela metade compilar:

```kotlin
// Todo.kt
fun weeklyGoal(course: String): Int = TODO("goals arrive in lesson 7")

fun main() {
    println("planner starting")
    println(weeklyGoal("Kotlin"))
}
```

```
ana@vm:~/kt/l03$ kotlinc Todo.kt -include-runtime -d todo.jar && java -jar todo.jar
planner starting
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented: goals arrive in lesson 7
	at TodoKt.weeklyGoal(Todo.kt:2)
	at TodoKt.main(Todo.kt:6)
	at TodoKt.main(Todo.kt)
```

O programa compila e roda, e para na primeira chamada que chega à função inacabada, com o motivo na
mensagem.
