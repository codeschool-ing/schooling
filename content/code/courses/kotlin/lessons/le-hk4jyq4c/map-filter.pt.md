---
title: map e filter
version: 1
---

A maior parte do que um programa faz com uma lista é uma de duas coisas: **ficar com alguns itens**,
ou **transformar cada item em outra coisa**. `filter` e `map` são essas duas, e são funções de ordem
superior exatamente como o `countWhere` da aula 4: um laço escrito uma vez, com a parte que varia
como lambda.

Até a aula 7 dar ao planejador classes próprias, uma sessão é um `Pair`: um curso e um número de
minutos, montado com `to`. `"Kotlin" to 45` é um `Pair<String, Int>`, e as duas metades são `first`
e `second`.

```schooling-example
{"language": "kotlin", "file": "MapFilter.kt", "parts": [{"code": "fun main() {\n    val sessions = listOf(\"Kotlin\" to 45, \"Android\" to 30, \"Kotlin\" to 60, \"Go\" to 20)", "note": "Quatro sessões. `to` é uma função escrita entre os dois argumentos, e a aula 11 mostra como declarar uma assim."}, {"code": "    println(sessions.filter { it.second >= 45 })", "note": "O `filter` fica com os itens para os quais a lambda diz `true`, na ordem original. O resultado é uma lista nova; `sessions` fica intocada."}, {"code": "    println(sessions.map { it.second })\n    println(sessions.map { \"${it.first}: ${it.second} min\" })", "note": "O `map` monta uma lista nova com um item para cada item da antiga, cada um o resultado da lambda. A lista nova pode ter outro tipo: `Int`, depois `String`."}, {"code": "    println(sessions.filter { it.first == \"Kotlin\" }.map { it.second }.sum())", "note": "As chamadas se encadeiam. Leia da esquerda para a direita: as sessões de Kotlin, os minutos delas, o total."}, {"code": "    println(sessions.mapNotNull { if (it.second >= 45) it.first else null })\n}", "note": "O `mapNotNull` transforma e descarta os resultados `null` num passo só, e o tipo do resultado é `List<String>`, não `List<String?>`."}]}
```

```
ana@vm:~/kt/l05$ kotlinc MapFilter.kt -include-runtime -d mapfilter.jar && java -jar mapfilter.jar
[(Kotlin, 45), (Kotlin, 60)]
[45, 30, 60, 20]
[Kotlin: 45 min, Android: 30 min, Kotlin: 60 min, Go: 20 min]
105
[Kotlin, Kotlin]
```

## Cada passo cria uma lista nova

`sessions.filter { … }.map { … }.sum()` montou duas listas a caminho de um número: a filtrada e a
transformada. **Para uma lista de quatro itens, ninguém nunca vai notar.** Para uma de um milhão, ou
uma corrente de seis passos, essas listas intermediárias são o custo, e a seção 07 mostra a
alternativa preguiçosa que não monta nenhuma delas.

## O laço que ela substitui

O mesmo total escrito como laço:

```kotlin
var total = 0
for (s in sessions) {
    if (s.first == "Kotlin") total += s.second
}
```

Os dois estão corretos. A corrente diz **o que** é calculado e o laço diz **como**, e a corrente não
tem um `var` que uma edição futura possa reaproveitar por engano. É por isso que código Kotlin pega a
corrente primeiro e guarda o laço para os casos em que várias coisas acontecem por item e dar nome a
elas ocuparia mais espaço que o laço.
