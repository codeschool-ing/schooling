---
title: O que uma data class deixa de fora
version: 1
---

Tudo o que uma data class gera é construído a partir **das propriedades do construtor primário, e de
nada mais**. É uma regra precisa, com consequências fáceis de perder.

## Uma propriedade no corpo é invisível para o `equals`

```kotlin
// Body.kt
data class Session(val course: String, val minutes: Int) {
    var note: String = ""
}

fun main() {
    val a = Session("Kotlin", 45).apply { note = "chapter 3" }
    val b = Session("Kotlin", 45).apply { note = "chapter 9" }
    println(a == b)
    println(a)
}
```

```
ana@vm:~/kt/l08$ kotlinc Body.kt -include-runtime -d body.jar && java -jar body.jar
true
Session(course=Kotlin, minutes=45)
```

Duas sessões com anotações diferentes são iguais, e o `toString` não mostra a anotação. Isso pode ser
de propósito, um valor em cache que não deve afetar a identidade, e **é um bug sempre que a propriedade
faz parte do que a sessão é**. Se ela pertence, vai para o construtor.

## Um array compara por identidade

```kotlin
// ArrayProp.kt
data class Week(val minutes: IntArray)

fun main() {
    println(Week(intArrayOf(45, 30)) == Week(intArrayOf(45, 30)))
    println(listOf(45, 30) == listOf(45, 30))
}
```

```
ana@vm:~/kt/l08$ kotlinc ArrayProp.kt -include-runtime -d arrayprop.jar && java -jar arrayprop.jar
false
true
```

Compilou sem uma palavra, e a resposta é `false`. **O `equals` de um array é `===`**, então o `equals`
gerado compara os dois arrays como objetos. Duas semanas com os mesmos minutos não são iguais. Uma
`List` compara os itens, como a segunda linha mostra, e é o que uma data class deve guardar.

## As regras que o compilador impõe

- o construtor primário precisa de **pelo menos um parâmetro, e todo parâmetro tem de ser `val` ou
  `var`**, já que um parâmetro simples não é propriedade e não teria como participar;
- uma data class **não pode ser `open`, `abstract` nem `inner`**: o `equals` e o `copy` gerados não
  sobrevivem à herança, porque uma subclasse teria propriedades de que o código gerado não sabe nada;
- ela **pode** implementar interfaces e estender outra classe, e pode declarar o próprio `toString` ou
  `equals`, e nesse caso o compilador não gera aquele.

A segunda regra importa para a lição 9. Uma família de formas de dados relacionadas, uma sessão que
está planejada, em andamento ou feita, não é uma data class com subclasses. É uma hierarquia selada,
cujos membros são cada um uma data class própria.
