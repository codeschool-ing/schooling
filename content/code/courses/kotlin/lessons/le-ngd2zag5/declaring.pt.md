---
title: Declarando uma função
version: 1
---

Uma função em Kotlin é `fun`, um nome, os parâmetros entre parênteses com um tipo depois de cada um,
e o tipo de retorno depois de dois-pontos. **Parâmetros sempre têm o tipo escrito**; é o único lugar
em que a inferência nunca se aplica, porque uma função é uma promessa a chamadores que o compilador
ainda não viu.

O planejador precisa do total das sessões de uma semana:

```schooling-example
{"language": "kotlin", "file": "Total.kt", "parts": [{"code": "fun total(minutes: List<Int>): Int {", "note": "Um parâmetro, uma lista de números inteiros, e a promessa de devolver um `Int`. `List<Int>` se lê como uma lista de `Int`; a aula 12 explica os sinais de menor e maior."}, {"code": "    var sum = 0\n    for (m in minutes) {\n        sum += m\n    }\n    return sum\n}", "note": "Um corpo de bloco: instruções entre chaves, e `return` para devolver o resultado. O `var` só existe dentro da função."}, {"code": "fun main() {\n    val week = listOf(45, 30, 60)\n    println(total(week))\n}", "note": "Uma chamada passa os valores na ordem em que os parâmetros foram declarados."}]}
```

```
ana@vm:~/kt/l03$ kotlinc Total.kt -include-runtime -d total.jar && java -jar total.jar
135
```

Um parâmetro é um `val`. **Dentro de `total`, `minutes = listOf()` não compila**, que é a mesma regra
da aula 1 aplicada aos nomes que quem chama entrega a você. Uma função que precisa mudar um valor
cria o próprio `var`, como `sum` aqui.

## O compilador verifica toda saída

Uma função que promete um `Int` precisa devolver um em todo caminho por ela. Esqueça um caminho, e o
compilador aponta a linha onde a função termina sem ele:

```kotlin
// Hours.kt
fun hours(minutes: Int): Int {
    if (minutes > 0) {
        return minutes / 60
    }
}

fun main() {
    println(hours(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc Hours.kt -include-runtime -d hours.jar
Hours.kt:6:1: error: missing return statement.
}
^
```

O caminho que falta é `minutes` zero ou menos. Em Java o mesmo descuido dá o mesmo erro; o que o
Kotlin acrescenta é a próxima seção, em que um `if` deixa de ser uma instrução e vira um valor, e o
`else` que falta passa a não compilar por outro motivo.

## Onde as funções moram

`total` está declarada no topo do arquivo, fora de qualquer classe. **O Kotlin chama isso de função
de nível superior, e é o lugar normal de uma função**, não um improviso. O Java precisaria de uma
classe com um método `static`, e a aula 1 mostrou que o compilador constrói exatamente isso por
você, `TotalKt`, fora da vista. A seção 06 volta a onde funções podem ser declaradas e quem as vê.

## Os argumentos são avaliados antes, da esquerda para a direita

`total(listOf(45, 30, 60))` monta a lista e depois chama `total`. Com vários argumentos, cada um é
avaliado na ordem escrita, antes de o corpo da função começar. Parece óbvio até um argumento ter um
efeito colateral, como imprimir ou ler um arquivo, e então a ordem é a diferença entre um log correto
e um confuso. O Kotlin garante essa ordem, mesmo com os argumentos nomeados da seção 04 escritos fora
de ordem.
