---
title: val e var
version: 1
---

O Kotlin tem duas palavras para um nome que guarda um valor, e a diferença é uma pergunta: **este
nome vai poder apontar para outra coisa depois?** `val` diz que não. `var` diz que sim. Quem chega de
outra linguagem tende a pegar a que muda, porque toda variável que já usou mudava; o hábito do Kotlin
é o contrário, e é o compilador que torna esse hábito barato.

O planejador de estudos que este curso constrói de lição em lição começa aqui, com um curso e os
minutos estudados nesta semana:

```schooling-example
{"language": "kotlin", "file": "Week.kt", "parts": [{"code": "fun main() {\n    val course = \"Kotlin\"", "note": "`val`: o nome `course` vai sempre significar esta string. Nada mais adiante na função consegue apontá-lo para outro lugar."}, {"code": "    var minutes = 0\n    minutes += 45\n    minutes += 30", "note": "`var`: um total acumulado precisa mudar, então é o único lugar onde um `var` se justifica. O `+=` lê o valor antigo, soma e guarda o novo."}, {"code": "    println(\"$course: $minutes minutes this week\")\n}", "note": "`$name` dentro de uma string insere o valor; a seção 07 mostra o resto da sintaxe."}], "output": "Kotlin: 75 minutes this week"}
```

```
ana@vm:~/kt/l01$ kotlinc Week.kt -include-runtime -d week.jar && java -jar week.jar
Kotlin: 75 minutes this week
```

## O que o compilador faz com uma segunda atribuição

Aponte um `val` para outro lugar e o programa não compila:

```kotlin
// Reassign.kt
fun main() {
    val course = "Kotlin"
    course = "Swift"
    println(course)
}
```

```
ana@vm:~/kt/l01$ kotlinc Reassign.kt -include-runtime -d reassign.jar
Reassign.kt:4:5: error: 'val' cannot be reassigned.
    course = "Swift"
    ^^^^^^
```

**Esse é o propósito do `val`**: a recusa acontece antes de qualquer coisa rodar, na sua máquina, e
não como um valor errado no celular de alguém. Um programa escrito quase todo com `val` se lê de cima
a baixo com uma promessa presa a cada nome, e os poucos `var` que sobram se destacam como os lugares
onde algo de fato muda.

A regra que a documentação do Kotlin e o guia de estilo do Android dão é a mesma: **declare com
`val`, e troque para `var` só quando o compilador mostrar que você precisa.**

## Um `val` é um nome fixo, não um valor congelado

O `val` fixa para qual objeto o nome aponta. Ele não diz nada sobre o objeto mudar por dentro:

```kotlin
// Sessions.kt
fun main() {
    val sessions = mutableListOf(45, 30)
    sessions.add(60)
    println(sessions)
    println(sessions.sum())
}
```

```
ana@vm:~/kt/l01$ kotlinc Sessions.kt -include-runtime -d sessions.jar && java -jar sessions.jar
[45, 30, 60]
135
```

`sessions` é `val`, e a lista para onde ele aponta cresceu de dois itens para três. O que o `val`
proíbe é `sessions = mutableListOf()`, uma segunda lista com o mesmo nome. Se a lista em si muda ou
não é decidido pelo tipo dela, e a lição 5 põe os dois tipos de lista lado a lado.

Então um `val` guardando uma lista mutável é uma coisa comum e correta de escrever. Um `var`
guardando uma lista mutável costuma ser uma mudança a mais: dois jeitos diferentes de os mesmos dados
se moverem, e quem lê precisa acompanhar os dois.
