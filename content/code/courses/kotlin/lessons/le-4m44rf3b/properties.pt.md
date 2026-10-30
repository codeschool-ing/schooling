---
title: Propriedades: getters, setters e o campo de apoio
version: 1
---

Uma propriedade em Kotlin não é um campo. **É um par de funções, um getter e, para um `var`, um
setter, que costumam ler e escrever um campo.** `s.done = true` chama o setter, e `s.done` chama o
getter, mesmo o código parecendo um acesso a campo. É por isso que uma propriedade pode passar depois
a calcular o valor ou a verificar o que é escrito, sem nenhum chamador mudar.

```schooling-example
{"language": "kotlin", "file": "Goal.kt", "parts": [{"code": "class Goal(val course: String, minutes: Int) {", "note": "`minutes` aqui é um parâmetro simples, então a classe consegue declarar uma propriedade com esse nome e regras próprias."}, {"code": "    var minutes: Int = minutes\n        set(value) {\n            require(value >= 0) { \"a goal cannot be negative: $value\" }\n            field = value\n        }", "note": "Um setter próprio. `value` é o que foi atribuído; `field` é o **campo de apoio**, o armazenamento por trás da propriedade. Escrever `minutes = value` aqui chamaria o setter de novo, para sempre."}, {"code": "    val hours: Double\n        get() = minutes / 60.0\n}", "note": "Uma propriedade só com getter e sem campo de apoio nenhum: ela é calculada a cada leitura."}, {"code": "fun main() {\n    val g = Goal(\"Kotlin\", 300)\n    println(g.hours)\n    g.minutes = 450\n    println(g.hours)\n    g.minutes = -5\n}", "note": "Ler `hours` depois de mudar `minutes` mostra o valor novo, porque nada foi guardado. A última linha passa pela verificação do setter."}]}
```

```
ana@vm:~/kt/l07$ kotlinc Goal.kt -include-runtime -d goal.jar && java -jar goal.jar
5.0
7.5
Exception in thread "main" java.lang.IllegalArgumentException: a goal cannot be negative: -5
	at Goal.setMinutes(Goal.kt:4)
	at GoalKt.main(Goal.kt:15)
	at GoalKt.main(Goal.kt)
```

O stack trace nomeia `Goal.setMinutes`: **`g.minutes = -5` foi uma chamada de função**, gerada a
partir da propriedade, que é o que o primeiro parágrafo afirmou.

## Uma propriedade calculada ou uma função

`val hours get() = …` e `fun hours() = …` fazem o mesmo trabalho. A convenção é sobre o que quem chama
pode supor: **uma propriedade deve ser barata, não ter efeitos colaterais e dar a mesma resposta duas
vezes seguidas** se nada mais mudou. `hours` se encaixa. Algo que lê um arquivo, ou conta um milhão de
itens, deve ser uma função, para o custo ficar visível como chamada.

## O setter é onde mora uma regra

A verificação no setter quer dizer que **nenhum código em lugar nenhum guarda uma meta negativa**, nem
o construtor, nem uma tela, nem um teste. Ponha a mesma verificação em cada chamador e o que esquecer
é o bug. O valor inicial não passou por setter nenhum, porém: `var minutes: Int = minutes` escreve no
campo direto quando o objeto é montado, então um valor negativo passado ao construtor entraria. Os
blocos `init` da seção 04 fecham essa brecha.

## A visibilidade de um setter

Um setter pode ser menos visível que o getter: `var total: Int = 0` seguido de `private set` dá uma
propriedade que todos leem e só a classe escreve. A seção 06 usa isso.
