---
title: Variância: por que uma lista de Int é uma lista de Number
version: 1
---

Um `Int` é um `Number`. Uma lista de `Int` é uma lista de `Number`? **Para uma lista que só se lê, sim;
para uma lista que se muda, não**, e os tipos do Kotlin dizem exatamente isso.

```kotlin
// Variance.kt
fun total(values: List<Number>): Double = values.sumOf { it.toDouble() }

fun main() {
    val minutes: List<Int> = listOf(45, 30)
    println(total(minutes))

    val log: MutableList<Int> = mutableListOf(45, 30)
    val numbers: MutableList<Number> = log
}
```

```
ana@vm:~/kt/l12$ kotlinc Variance.kt -include-runtime -d variance.jar
Variance.kt:9:38: error: initializer type mismatch: expected 'MutableList<Number>', actual 'MutableList<Int>'.
    val numbers: MutableList<Number> = log
                                     ^
```

`List<Int>` entrou num parâmetro `List<Number>`. `MutableList<Int>` foi recusada como
`MutableList<Number>`, e o motivo é o que a segunda poderia fazer: **uma `MutableList<Number>` aceita
`add(2.5)`**, e se `numbers` e `log` fossem a mesma lista, um `Double` estaria agora numa lista de
`Int`, e a próxima linha que lesse `log[2]` como `Int` falharia. Uma `List` somente leitura não tem
`add`, então o perigo não existe, e o compilador permite.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-variance\" aria-label=\"Três linhas. List&lt;Int&gt; para List&lt;Number&gt;: permitido, porque List é out e só entrega valores. MutableList&lt;Int&gt; para MutableList&lt;Number&gt;: recusado, porque uma MutableList&lt;Number&gt; aceitaria add(2.5) numa lista de Int. Comparator&lt;Number&gt; para Comparator&lt;Int&gt;: permitido no sentido oposto, porque Comparator é in e só recebe valores.\"><defs><marker id=\"l12-variance-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-variance-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">List&lt;Int&gt;</text><rect x=\"330\" y=\"30\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">List&lt;Number&gt;</text><path d=\"M222 50 L328 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-variance-ah-phosphor)\"></path><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabe</text><text x=\"625\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">out: só entrega valores</text><rect x=\"20\" y=\"102\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MutableList&lt;Int&gt;</text><rect x=\"330\" y=\"102\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">MutableList&lt;Number&gt;</text><path d=\"M222 122 L328 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-variance-ah-amber)\"></path><text x=\"275\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">não</text><text x=\"625\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado: add(2.5) entraria</text><rect x=\"20\" y=\"174\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Comparator&lt;Number&gt;</text><rect x=\"330\" y=\"174\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Comparator&lt;Int&gt;</text><path d=\"M222 194 L328 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-variance-ah-phosphor)\"></path><text x=\"275\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabe</text><text x=\"625\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">in: só recebe valores</text></svg>", "caption": "Se X<Int> cabe onde se quer X<Number> depende de X só produzir valores, só consumi-los, ou os dois."}
```

## `out`: um tipo que só produz T

`List` é declarada `interface List<out E>`. **O `out` num parâmetro de tipo promete que o tipo só
entrega `E`**, como resultado, e nunca recebe um, e essa promessa é o que torna `List<Int>` usável como
`List<Number>`. Isso se chama covariância. O compilador cobra a promessa de uma classe:

```kotlin
// Out.kt
class Source<out T>(private val item: T) {
    fun get(): T = item
    fun put(value: T) {}
}

fun main() {
    println(Source(45).get())
}
```

```
ana@vm:~/kt/l12$ kotlinc Out.kt -include-runtime -d out.jar
Out.kt:4:20: error: type parameter 'T' is declared as 'out' but occurs in 'in' position in type 'T (of class Source<out T>)'.
    fun put(value: T) {}
                   ^
```

O `put` recebe um `T` como parâmetro, uma posição **in**, que o `out` proíbe. Tire o `put` e
`Source<Int>` passa a ser usável onde se espera uma `Source<Number>`, pelo mesmo motivo da `List`.
`MutableList<E>` não tem `out` porque tem `add(element: E)`, e por isso é **invariante**: uma
`MutableList<Int>` é uma `MutableList<Int>` e nada mais.
