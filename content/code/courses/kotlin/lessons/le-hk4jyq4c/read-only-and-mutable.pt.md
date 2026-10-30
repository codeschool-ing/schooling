---
title: Listas somente leitura e listas mutáveis
version: 1
---

A aula 1 deixou uma promessa: se uma lista muda ou não é decidido pelo tipo dela. O Kotlin tem
**dois tipos de lista onde o Java tem um**. `List<Int>` tem `get`, `size`, `contains` e toda função de
leitura, e nenhum `add`. `MutableList<Int>` tem tudo isso, mais `add`, `remove` e `set`. A mesma
divisão existe para conjuntos e mapas.

```kotlin
// Lists.kt
fun main() {
    val week: List<Int> = listOf(45, 30, 60)
    val log: MutableList<Int> = mutableListOf(45, 30)
    log.add(60)
    log.removeAt(0)
    println(week)
    println(log)
    println(week[1])
    println(week.size)
}
```

```
ana@vm:~/kt/l05$ kotlinc Lists.kt -include-runtime -d lists.jar && java -jar lists.jar
[45, 30, 60]
[30, 60]
30
3
```

`week[1]` é `week.get(1)` escrito com colchetes, e as posições começam em 0. Peça à lista somente
leitura para mudar, e o compilador nem encontra a função:

```kotlin
// AddToList.kt
fun main() {
    val week: List<Int> = listOf(45, 30, 60)
    week.add(90)
}
```

```
ana@vm:~/kt/l05$ kotlinc AddToList.kt -include-runtime -d addtolist.jar
AddToList.kt:4:10: error: unresolved reference 'add' on receiver of type 'List<Int>'.
    week.add(90)
         ^^^
```

## Somente leitura não é imutável

`List` quer dizer que **você** não muda a lista por este nome. Não promete que ninguém muda:

```kotlin
// View.kt
fun main() {
    val log = mutableListOf(45, 30)
    val view: List<Int> = log
    log.add(60)
    println(view)
}
```

```
ana@vm:~/kt/l05$ kotlinc View.kt -include-runtime -d view.jar && java -jar view.jar
[45, 30, 60]
```

`view` e `log` são a mesma lista, vista por dois tipos. `view` não tem `add`, e a lista cresceu mesmo
assim, porque `log` tem. **Um parâmetro `List` é uma promessa da função de não mudar o que recebeu**,
o que é útil e não é o mesmo que os dados estarem congelados. Quando uma função precisa entregar uma
lista que ninguém mude depois, ela entrega uma cópia: `log.toList()` monta uma lista nova com os
mesmos itens.

## Qual delas declarar

A regra é a da aula 1, um nível abaixo. **Declare `List` e exponha `List`; mantenha uma `MutableList`
privada no código que a preenche.** Uma função que monta uma lista usa uma `MutableList` por dentro e
a devolve como `List`, e o `buildList { … }` da biblioteca padrão faz exatamente isso numa chamada:

```kotlin
// Build.kt
fun plannedWeek(): List<Int> = buildList {
    add(45)
    add(30)
    if (true) add(60)
}

fun main() {
    println(plannedWeek())
}
```

```
ana@vm:~/kt/l05$ kotlinc Build.kt -include-runtime -d build.jar && java -jar build.jar
[45, 30, 60]
```

Dentro das chaves o `add` está disponível, porque o bloco trabalha sobre uma `MutableList`. O que sai
tem o tipo `List<Int>`, então nenhum chamador consegue acrescentar nada. A aula 17 usa o mesmo padrão
para o estado que um app observa: um valor mutável privado, e um somente leitura entregue para fora.
