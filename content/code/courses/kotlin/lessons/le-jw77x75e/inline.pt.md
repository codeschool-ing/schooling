---
title: inline, e o return que sai da função de fora
version: 1
---

A seção 02 mostrou uma lambda como um objeto com um método `invoke`. Passar uma custa um objeto, e
chamá-la custa uma chamada através desse objeto. **Uma função `inline` pede ao compilador que copie o
corpo dela, e o corpo da lambda passada a ela, para cada lugar onde ela é chamada**, de modo que nem o
objeto nem a chamada existem em tempo de execução.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-inline\" aria-label=\"Duas colunas comparam uma chamada, repeat(2) { println(it) }. À esquerda, sem inline: o main cria um objeto Function1 com a lambda, chama repeat, que chama invoke no objeto duas vezes. À direita, com inline: o compilador copia o laço e o println para dentro do main, então o main contém o laço diretamente e não existe objeto nem chamada extra em tempo de execução.\"><defs><marker id=\"l04-inline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">repeat(2) { println(it) }</text><text x=\"180\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">sem inline</text><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">com inline</text><rect x=\"40\" y=\"66\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">main: novo objeto lambda</text><path d=\"M180 106 L180 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inline-ah-amber)\"></path><rect x=\"40\" y=\"130\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">repeat(2, lambda)</text><path d=\"M180 170 L180 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inline-ah-amber)\"></path><rect x=\"40\" y=\"194\" width=\"280\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda.invoke(0)</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda.invoke(1)</text><text x=\"180\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um objeto, e uma chamada por item</text><rect x=\"400\" y=\"66\" width=\"280\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">main, depois que o compilador copiou</text><rect x=\"420\" y=\"104\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for (i in 0 until 2) {</text><text x=\"540\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">    println(i)</text><text x=\"540\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">nenhum objeto, nenhuma chamada extra</text><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o próprio código, onde estava a chamada</text></svg>", "caption": "Uma função inline não é chamada: o corpo dela, e o da lambda, são copiados para quem chama."}
```

A aula 1 encontrou isso sem o nome: o `println` é inline, e é por isso que o corpo dele foi parar no
`HelloKt`. Toda função de coleção da aula 5 é inline pelo mesmo motivo, e o `repeat` também.

## O `return` que o inline permite

Copiar o corpo da lambda para quem chama tem uma consequência para o `return`. Dentro da lambda de
uma função inline, **um `return` simples sai da função em que a lambda foi escrita**, porque depois de
copiado é literalmente ali que o código fica. Isso se chama retorno não local:

```kotlin
// Inline.kt
fun firstLong(week: List<Int>): Int? {
    week.forEach { if (it >= 60) return it }
    return null
}

fun printUntilLong(week: List<Int>) {
    week.forEach {
        if (it >= 60) return@forEach
        println("short: $it")
    }
    println("done")
}

fun main() {
    println(firstLong(listOf(45, 90, 30)))
    println(firstLong(listOf(20)))
    printUntilLong(listOf(45, 90, 30))
}
```

```
ana@vm:~/kt/l04$ kotlinc Inline.kt -include-runtime -d inline.jar && java -jar inline.jar
90
null
short: 45
short: 30
done
```

O `forEach` é inline, então `return it` em `firstLong` retorna de `firstLong`, o que se lê como o laço
que ele substitui. Em `printUntilLong`, **`return@forEach` retorna só da lambda**: pula o 90 e segue
com o 30, como um `continue` faria num laço, e depois `done` é impresso. O rótulo é o nome da função
para a qual a lambda foi passada.

## Por que uma lambda comum recusa

Uma função que não é inline guarda a lambda como objeto, que pode ser armazenado e chamado depois,
muito depois de a função de fora ter retornado. Um `return` de dentro dela não teria para onde ir:

```kotlin
// NotInline.kt
fun twice(action: () -> Unit) {
    action()
    action()
}

fun stopEarly() {
    twice { return }
    println("unreachable?")
}

fun main() {
    stopEarly()
}
```

```
ana@vm:~/kt/l04$ kotlinc NotInline.kt -include-runtime -d notinline.jar
NotInline.kt:8:13: error: 'return' is prohibited here.
    twice { return }
            ^^^^^^
```

**Esta é a regra da seção 03, explicada**: um `return` simples pertence à `fun` mais próxima, e só é
permitido numa lambda quando a lambda é copiada para dentro dessa `fun`. Declare `twice` como
`inline fun` e o mesmo arquivo compila.

## Quando escrever `inline` você mesmo

Raramente. Vale a pena quando uma função recebe uma lambda e é chamada com frequência, e a biblioteca
padrão já fez isso nas funções que você mais chama. Fazer inline de uma função grande a copia para
todo chamador, o que aumenta o programa, e o compilador avisa quando o `inline` não compra nada, numa
função sem parâmetros de função. A aula 12 encontra o único caso em que o `inline` é obrigatório e
não uma otimização: os parâmetros de tipo `reified`.
