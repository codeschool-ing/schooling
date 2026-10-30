---
title: Delegação de classe com by
version: 1
---

Às vezes uma classe quer ser uma `MutableList` com um comportamento mudado, digamos uma lista que
registra cada acréscimo. Herdar de `ArrayList` a prende a uma implementação e a toda chamada interna
que o `ArrayList` faz. **A delegação implementa a interface entregando cada chamada a um objeto que
você escolhe, e deixa você trocar só as que importam.** O Kotlin escreve a entrega por você:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l11-delegation\" aria-label=\"Uma chamada chega ao LoggingList. Se é add, a sobrescrita no LoggingList roda, imprime uma linha e então chama inner.add. Todo outro membro de MutableList, size, get, remove e o resto, é repassado por código que o compilador gerou direto para a lista interna. toString, equals e hashCode não são membros da interface e não são repassados.\"><defs><marker id=\"l11-delegation-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-delegation-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"70\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma chamada</text><rect x=\"150\" y=\"20\" width=\"250\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">LoggingList</text><rect x=\"170\" y=\"60\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">override fun add</text><text x=\"275\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">imprime, depois inner.add</text><rect x=\"170\" y=\"116\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"275\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repasse gerado:</text><text x=\"275\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">size, get, remove, …</text><text x=\"275\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">toString: não repassado</text><path d=\"M40 82 L168 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-amber)\"></path><path d=\"M40 138 L168 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-paper-dim)\"></path><text x=\"70\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add(45)</text><text x=\"70\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">size</text><rect x=\"500\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">inner</text><text x=\"595\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">MutableList&lt;Int&gt;</text><path d=\"M380 82 L498 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-amber)\"></path><path d=\"M380 138 L498 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-paper-dim)\"></path></svg>", "caption": "by inner repassa todo membro da interface; a classe sobrescreve só os que muda."}
```

```kotlin
// Delegation.kt
class LoggingList(
    private val inner: MutableList<Int> = mutableListOf(),
) : MutableList<Int> by inner {
    override fun add(element: Int): Boolean {
        println("adding $element")
        return inner.add(element)
    }
}

fun main() {
    val log = LoggingList()
    log.add(45)
    log.add(30)
    println(log.size)
    println(log.sum())
    println(log)
}
```

```
ana@vm:~/kt/l11$ kotlinc Delegation.kt -include-runtime -d delegation.jar && java -jar delegation.jar
adding 45
adding 30
2
75
LoggingList@4617c264
```

`: MutableList<Int> by inner` diz: implemente `MutableList` repassando para `inner`. A interface tem uns
trinta membros, e o compilador escreveu um método de repasse para cada um, menos o `add`, que a classe
sobrescreve. `size` e `sum()` foram direto para a lista interna.

## O que o `by` não repassa

A última linha imprimiu `LoggingList@` e um hash code, não `[45, 30]`. **A delegação repassa os membros
da interface, e o `toString` não é um deles**: ele vem do `Any`, que toda classe herda, e o
`LoggingList` tem o padrão. O mesmo vale para `equals` e `hashCode`. Quando o invólucro deve imprimir
ou comparar como a coisa que embrulha, ele mesmo sobrescreve esses três:
`override fun toString() = inner.toString()`.

A segunda armadilha é mais sutil. Uma chamada repassada roda no `inner`, então se o próprio `addAll`
do `inner` chama o próprio `add`, essa chamada vai para o `add` da lista interna, e não para a
sobrescrita. **Uma sobrescrita pega as chamadas feitas no invólucro, e só elas.** Com herança seria o
contrário, que é justamente o acoplamento escondido que a delegação evita.

## Por que isso importa no Android

"Prefira composição a herança" é conselho de todo guia de estilo, e em Java significa escrever os
métodos de repasse à mão. Em Kotlin é uma palavra, e é por isso que o código Kotlin recorre a ela onde
o código Java teria criado uma subclasse.
