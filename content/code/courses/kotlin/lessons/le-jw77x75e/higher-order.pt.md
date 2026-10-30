---
title: Funções de ordem superior
version: 1
---

Uma função que recebe uma função como parâmetro, ou devolve uma, se chama **de ordem superior**. O
nome é mais pomposo que a ideia: é uma função com um buraco, onde quem chama fornece a parte que
varia.

O planejador quer contar sessões: as longas, as curtas, as do fim de semana. A contagem é a mesma
toda vez e só a pergunta muda, então a pergunta vira parâmetro:

```kotlin
// HigherOrder.kt
fun countWhere(minutes: List<Int>, test: (Int) -> Boolean): Int {
    var count = 0
    for (m in minutes) {
        if (test(m)) count++
    }
    return count
}

fun scaledBy(factor: Int): (Int) -> Int = { it * factor }

fun main() {
    val week = listOf(45, 30, 60, 90, 20)
    println(countWhere(week, { it >= 60 }))
    println(countWhere(week, { it < 30 }))
    val triple = scaledBy(3)
    println(triple(20))
    println(scaledBy(2)(45))
}
```

```
ana@vm:~/kt/l04$ kotlinc HigherOrder.kt -include-runtime -d higherorder.jar && java -jar higherorder.jar
2
1
60
90
```

`countWhere` recebe uma lista e um `(Int) -> Boolean`, e chama `test(m)` para cada item. **O laço é
escrito uma vez**, e toda pergunta sobre sessões agora é uma linha na chamada. Sem ele cada pergunta
seria um laço próprio, de cinco linhas cada, com a única linha que muda enterrada no meio.

`scaledBy` vai no sentido contrário: ela **devolve** uma função. `scaledBy(3)` monta uma lambda que
multiplica por 3 e a entrega, e `triple(20)` a chama. A última linha chama a função devolvida na
hora, `scaledBy(2)(45)`, o que é legal e raramente mais claro do que dar um nome antes.

## Isso é a maior parte da biblioteca padrão

A aula 5 é um passeio por funções com exatamente a forma de `countWhere`: `count`, `filter`, `map`,
`any`, `sortedBy`, `groupBy`. Cada uma recebe uma coleção e uma lambda, e **cada uma substitui um laço
que você escreveria à mão**. A biblioteca padrão já tem `count`, então em código real `countWhere` é
`week.count { it >= 60 }`, que a próxima seção explica.

## Quanto custa um parâmetro de função

Cada lambda passada a `countWhere` é um objeto, criado na chamada. Para uma função chamada poucas
vezes isso não é nada. Para uma chamada num laço apertado num celular, é uma alocação por chamada, que
é o que o `inline` da seção 08 elimina, e o motivo de as funções de coleção da biblioteca padrão
serem todas declaradas `inline`.
