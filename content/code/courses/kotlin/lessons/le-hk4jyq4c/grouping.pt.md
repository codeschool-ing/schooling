---
title: groupBy, associate e partition
version: 1
---

A tela semanal do planejador mostra um total por curso. Essa é a pergunta "agrupe as sessões por
curso, depois some cada grupo", e **o `groupBy` é a primeira metade dela**: devolve um mapa de cada
chave para a lista dos itens que a têm.

```kotlin
// Grouping.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60, "Go" to 20)

    val byCourse = sessions.groupBy { it.first }
    println(byCourse)
    println(byCourse.mapValues { (_, list) -> list.sumOf { it.second } })

    val (long, short) = sessions.partition { it.second >= 45 }
    println(long)
    println(short)

    println(sessions.associate { it.first to it.second })
    println(sessions.groupingBy { it.first }.eachCount())
}
```

```
ana@vm:~/kt/l05$ kotlinc Grouping.kt -include-runtime -d grouping.jar && java -jar grouping.jar
{Kotlin=[(Kotlin, 45), (Kotlin, 60)], Android=[(Android, 30)], Go=[(Go, 20)]}
{Kotlin=105, Android=30, Go=20}
[(Kotlin, 45), (Kotlin, 60)]
[(Android, 30), (Go, 20)]
{Kotlin=60, Android=30, Go=20}
{Kotlin=2, Android=1, Go=1}
```

Leia as duas primeiras linhas da saída juntas. **O `groupBy` guarda todas as sessões**, arquivadas
pelo curso, e os cursos aparecem na ordem em que cada um foi visto pela primeira vez. O `mapValues`
então transforma cada lista no total dela. A lambda desmonta a entrada do mapa em chave e valor,
`(_, list)`, com `_` para a chave de que não precisa; a lição 8 explica essa sintaxe, chamada
desestruturação.

## partition

O `partition` é um `filter` que guarda as duas metades: os itens que passaram e os que não passaram.
Ele devolve um `Pair` de duas listas, e `val (long, short) = …` desmonta o par em dois nomes, a mesma
desestruturação de novo.

## associate, e a chave que aparece duas vezes

O `associate` monta um mapa com uma entrada por item. As sessões têm `Kotlin` duas vezes, e **um mapa
guarda um valor por chave**, então a saída tem `Kotlin=60`: a segunda sessão substituiu a primeira,
sem dizer nada. Esse é o comportamento certo quando as chaves são únicas, um id por sessão por
exemplo, e uma perda silenciosa de dados quando não são. Quando você não tem certeza de que as chaves
são únicas, o `groupBy` é o que não perde nada.

## groupingBy

`groupingBy { … }.eachCount()` conta por chave sem montar as listas que o `groupBy` montaria. É a
forma eficiente de `groupBy { … }.mapValues { it.value.size }`, e o `groupingBy` tem também `fold` e
`reduce` por grupo, que são o assunto da próxima seção.
