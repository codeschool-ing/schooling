---
title: Escolhendo uma, e quando não usar nenhuma
version: 1
---

A documentação do Kotlin dá um guia curto, e são as duas perguntas de novo, na ordem em que você as
faria:

| você quer | use |
|---|---|
| rodar um bloco só quando um valor não é null | `?.let` |
| configurar um objeto e recebê-lo de volta | `apply` |
| fazer algo a mais com um objeto numa corrente, e passá-lo adiante | `also` |
| calcular um resultado a partir de um objeto, com os membros sem prefixo | `run`, ou `with` quando não é uma corrente |
| calcular um resultado com nomes temporários próprios | `run` sem objeto |

**Nenhuma delas é obrigatória.** Cada uma se escreve como instruções simples com um `val` nomeado, e às
vezes esse é o código mais claro. O custo de uma função de escopo é que quem lê precisa saber qual das
cinco ela é antes de conseguir ler o bloco.

## Aninhar torna o `this` ambíguo

Um receptor pode ser omitido, que é o propósito, e que dá errado quando dois receptores estão em escopo
ao mesmo tempo. Dentro de blocos aninhados, uma chamada sem prefixo vai para o receptor **mais
interno** que tem um membro com aquele nome, e só então para fora:

```kotlin
// Nested.kt
fun main() {
    val report = StringBuilder()
    val week = mutableListOf(45, 30)
    report.apply {
        week.apply {
            add(60)
            append("week: $this, ")
            append("size $size")
        }
    }
    println(report)
}
```

```
ana@vm:~/kt/l06$ kotlinc Nested.kt -include-runtime -d nested.jar && java -jar nested.jar
week: [45, 30, 60], size 3
```

`add` e `size` pertencem à lista, o receptor interno. O `append` não existe numa lista, então achou o
builder, o externo. E `this` é sempre o mais interno, a lista. **O programa está correto e quem lê
precisa resolver cada chamada à mão para saber disso.** `apply`, `run` ou `with` aninhados são o caso
em que dar nomes compensa: `report.append(…)`, ou `also` e `let` com um nome para o parâmetro, dizem
de qual objeto cada linha está falando.

## Correntes longas delas

`x.let { … }.also { … }.run { … }.apply { … }` compila. **Duas seguidas já são motivo para parar e dar
nome ao valor intermediário**, porque cada uma muda o que `it` e `this` significam, e quem lê precisa
segurar tudo isso ao mesmo tempo. As funções de escopo economizam uma linha quando economizam um nome;
quando passam a custar entendimento, a linha saía mais barata.
