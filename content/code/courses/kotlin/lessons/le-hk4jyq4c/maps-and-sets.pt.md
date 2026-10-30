---
title: Mapas e conjuntos
version: 1
---

Uma lista guarda itens em ordem e aceita repetições. **Um conjunto não aceita repetição**, e um
**mapa** arquiva cada valor sob uma chave. Os dois vêm numa versão somente leitura e numa mutável,
como as listas.

```kotlin
// MapsSets.kt
fun main() {
    val goals = mapOf("Kotlin" to 300, "Android" to 240)
    println(goals["Kotlin"])
    println(goals["Swift"])
    println(goals.getOrDefault("Swift", 0))
    println(goals.getValue("Android"))

    val done = mutableMapOf<String, Int>()
    done["Kotlin"] = 45
    done["Kotlin"] = done.getOrDefault("Kotlin", 0) + 60
    done.merge("Android", 30, Int::plus)
    println(done)

    for ((course, goal) in goals) {
        val left = goal - (done[course] ?: 0)
        println("$course: $left min to go")
    }

    val studied = setOf("Kotlin", "Android", "Kotlin")
    println(studied)
    println("Swift" in studied)
}
```

```
ana@vm:~/kt/l05$ kotlinc MapsSets.kt -include-runtime -d mapssets.jar && java -jar mapssets.jar
300
null
0
240
{Kotlin=105, Android=30}
Kotlin: 195 min to go
Android: 210 min to go
[Kotlin, Android]
false
```

## Ler um mapa dá um valor anulável

`goals["Swift"]` imprimiu `null`, e o tipo dele é `Int?`. **Um mapa não promete que uma chave
existe**, então toda leitura simples é anulável, e as ferramentas da lição 2 a respondem:
`getOrDefault`, ou `?: 0` como no laço. O `getValue` é a leitura que promete: devolve um `Int` e lança
`NoSuchElementException` quando a chave falta, o que é o certo quando uma chave ausente é um bug.

## Escrevendo num mapa mutável

`done["Kotlin"] = 45` põe um valor sob uma chave, substituindo o que já estivesse lá. Somar a um
valor existente é uma leitura e uma escrita, e o `merge` faz as duas: põe 30 sob `Android` se não há
nada lá, ou combina com o que há usando a função dada, aqui `Int::plus`, uma referência ao `+` do
`Int`.

`for ((course, goal) in goals)` percorre as entradas do mapa e desmonta cada uma em chave e valor.

## Conjuntos

`setOf("Kotlin", "Android", "Kotlin")` tem dois itens: o segundo `Kotlin` foi descartado. **O `in`
pergunta se um item está lá**, e num conjunto faz isso sem percorrer todos os itens, que é para isso
que um conjunto existe. O `in` funciona em listas e mapas também, onde `"Kotlin" in goals` pergunta
sobre as chaves; numa lista, ele precisa olhar item por item.

## A ordem de um mapa ou conjunto

`mapOf`, `mutableMapOf` e `setOf` mantêm a ordem em que os itens foram acrescentados, e é por isso que
a saída sai na ordem em que o programa escreveu. Isso é uma propriedade das implementações padrão, um
`LinkedHashMap` e um `LinkedHashSet` na JVM, e não de todo mapa: o `HashMap` não promete ordem
nenhuma, e um código que depende da ordem deve dizer isso escolhendo o tipo que a mantém.
