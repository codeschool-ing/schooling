---
title: fold e reduce
version: 1
---

`sumOf`, `count` e `maxOf` são, cada um, um laço que carrega um valor de item em item, um acumulador,
e o devolve no fim. **O `fold` é esse laço sem nada decidido**: você dá o valor inicial e o passo, e
ele carrega o acumulador pela lista.

```kotlin
// Fold.kt
fun main() {
    val minutes = listOf(45, 30, 60, 20)

    val total = minutes.fold(0) { acc, m -> acc + m }
    println(total)

    val report = minutes.fold("week:") { acc, m -> "$acc $m" }
    println(report)

    val longestRun = minutes.fold(0 to 0) { (best, run), m ->
        val now = if (m >= 30) run + 1 else 0
        maxOf(best, now) to now
    }
    println(longestRun.first)

    println(minutes.reduce { acc, m -> acc + m })
    println(minutes.runningFold(0) { acc, m -> acc + m })
}
```

```
ana@vm:~/kt/l05$ kotlinc Fold.kt -include-runtime -d fold.jar && java -jar fold.jar
155
week: 45 30 60 20
3
155
[0, 45, 75, 135, 155]
```

`fold(0) { acc, m -> acc + m }` começa em 0 e soma cada item, que é o `sum()` escrito por extenso. O
segundo fold mostra que **o acumulador pode ser de qualquer tipo**, aqui uma `String` que cresce. O
terceiro é onde o `fold` se justifica: a maior sequência seguida de sessões de meia hora ou mais, que
nenhuma função com nome responde. O acumulador dele é um par, a melhor sequência até agora e a atual,
e cada passo devolve o próximo par.

## reduce

O `reduce` é o `fold` que usa o primeiro item como valor inicial. É mais curto quando a resposta tem o
mesmo tipo dos itens, e tem o problema da lista vazia da seção 04: sem primeiro item não há valor
inicial, e ele lança exceção.

```kotlin
// Reduce.kt
fun main() {
    val none = emptyList<Int>()
    println(none.fold(0) { acc, m -> acc + m })
    println(none.reduceOrNull { acc, m -> acc + m })
    println(none.reduce { acc, m -> acc + m })
}
```

```
ana@vm:~/kt/l05$ kotlinc Reduce.kt -include-runtime -d reduce.jar && java -jar reduce.jar
0
null
Exception in thread "main" java.lang.UnsupportedOperationException: Empty collection can't be reduced.
	at ReduceKt.main(Reduce.kt:20)
	at ReduceKt.main(Reduce.kt)
```

**O `fold` tem resposta para uma lista vazia, porque você deu uma.** Isso o torna o padrão mais
seguro, e o `reduce` a abreviação para listas que você sabe que não estão vazias.

## runningFold

A última linha do `Fold.kt` imprimiu todos os acumuladores intermediários, não só o final: o
`runningFold` é o `fold` que guarda o rascunho. Para o planejador, é um total acumulado ao longo da
semana, a linha que um gráfico de progresso desenha, e ele tem um item a mais que a lista, porque
inclui o valor inicial.
