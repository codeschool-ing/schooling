---
title: try como expressão, catch e finally
version: 1
---

O `try` em Kotlin é uma expressão, como o `if` e o `when`: **o valor dele é o do bloco `try` se nada
foi lançado, ou o do bloco `catch` que rodou**.

```kotlin
// TryExpr.kt
fun minutesOrZero(text: String): Int = try {
    text.trim().toInt()
} catch (e: NumberFormatException) {
    println("not a number: '$text'")
    0
} finally {
    println("checked '$text'")
}

fun main() {
    println(minutesOrZero("45"))
    println(minutesOrZero("forty"))
}
```

```
ana@vm:~/kt/l13$ kotlinc TryExpr.kt -include-runtime -d tryexpr.jar && java -jar tryexpr.jar
checked '45'
45
not a number: 'forty'
checked 'forty'
0
```

Acompanhe a segunda chamada. O `toInt()` lançou, o `catch` para `NumberFormatException` rodou e a
última expressão dele, `0`, virou o valor do `try`. Depois **o `finally` rodou, acontecesse o que
acontecesse**, antes de a função retornar. Na primeira chamada nada foi lançado, o `catch` foi pulado e
o `finally` rodou mesmo assim. O valor do próprio bloco `finally` é ignorado; ele serve para limpeza,
não para resultados.

## Pegue o que você espera, pelo nome

`catch (e: NumberFormatException)` pega essa exceção e as subclasses dela, e nada mais. **Um
`catch (e: Exception)` pega todo bug também**, e o transforma no mesmo `0`:

```kotlin
// TooBroad.kt
fun minutesOrZero(text: String?): Int = try {
    text!!.trim().toInt()
} catch (e: Exception) {
    0
}

fun main() {
    println(minutesOrZero("forty"))
    println(minutesOrZero(null))
}
```

```
ana@vm:~/kt/l13$ kotlinc TooBroad.kt -include-runtime -d toobroad.jar && java -jar toobroad.jar
0
0
```

Os dois imprimiram `0`. O segundo não era uma estudante digitando uma palavra; era um `null` que nunca
deveria ter chegado a esta função, um bug em outro lugar, e o `catch` largo o fez parecer uma entrada
comum. **Um catch que nomeia a única exceção que você espera deixa toda outra falha continuar
barulhenta.** A aula 15 acrescenta um motivo mais forte: em código de corrotina, pegar `Exception`
também pega o sinal que cancela uma tarefa, e a tarefa então se recusa a parar.

## Vários catch

Um `try` pode ter vários blocos `catch`, testados em ordem, e roda o primeiro cujo tipo bate. Ponha o
mais específico primeiro: um `catch (e: Exception)` acima de um `catch (e: NumberFormatException)`
pegaria tudo, e o específico abaixo dele nunca rodaria.
