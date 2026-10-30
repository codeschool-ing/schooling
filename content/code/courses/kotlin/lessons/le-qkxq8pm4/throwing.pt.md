---
title: Exceções em Kotlin: sem exceções verificadas
version: 1
---

Uma exceção para a função que a lança, e a que a chamou, e assim por diante subindo pelas chamadas,
**até algo pegá-la ou o programa terminar**. Essa parte é igual ao Java. O que o Kotlin tirou foram as
exceções verificadas do Java: nenhuma função declara o que lança, e nenhum chamador é obrigado a pegar
nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-unwind\" aria-label=\"Quatro chamadas empilhadas, main embaixo, depois total, depois minutesFrom, depois toInt no alto. O toInt lança NumberFormatException. Uma seta mostra a exceção descendo por minutesFrom, total e main, que não a pegam, e saindo do programa, que termina com um stack trace listando as mesmas chamadas da mais interna para fora.\"><defs><marker id=\"l13-unwind-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">toInt()</text><rect x=\"60\" y=\"70\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutesFrom(\"forty\")</text><rect x=\"60\" y=\"120\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">total(lines)</text><rect x=\"60\" y=\"170\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main()</text><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lança NumberFormatException</text><path d=\"M330 40 C 360 40 360 190 330 190\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-unwind-ah-amber)\"></path><text x=\"470\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum catch aqui</text><text x=\"470\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum catch aqui</text><text x=\"470\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum catch aqui</text><path d=\"M190 200 L190 236\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-unwind-ah-amber)\"></path><text x=\"470\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">o programa termina: stack trace</text></svg>", "caption": "Uma exceção não pega sai de cada chamada no caminho, a mais interna primeiro, até algo pegá-la ou o programa terminar."}
```

```kotlin
// Throw.kt
fun minutesFrom(text: String): Int = text.trim().toInt()

fun total(lines: List<String>): Int = lines.sumOf { minutesFrom(it) }

fun main() {
    println(total(listOf("45", "30")))
    println(total(listOf("45", "forty")))
}
```

```
ana@vm:~/kt/l13$ kotlinc Throw.kt -include-runtime -d throw.jar && java -jar throw.jar
75
Exception in thread "main" java.lang.NumberFormatException: For input string: "forty"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at java.base/java.lang.Integer.parseInt(Integer.java:778)
	at ThrowKt.minutesFrom(Throw.kt:2)
	at ThrowKt.total(Throw.kt:4)
	at ThrowKt.main(Throw.kt:8)
	at ThrowKt.main(Throw.kt)
```

O `toInt()` lançou `NumberFormatException` para `"forty"`. Nada em `minutesFrom`, `total` ou `main` a
pegou, então ela subiu pelas três, que o stack trace lista da chamada mais interna para fora, e o
programa terminou. **O trace se lê de baixo para cima para o caminho, e pela primeira linha para a
causa**: a primeira linha nomeia a exceção e a entrada.

## Por que o Kotlin abandonou as exceções verificadas

Em Java, um método que pode falhar com `IOException` precisa declarar `throws IOException`, e todo
chamador precisa pegá-la ou declará-la por sua vez. A intenção era que nenhuma falha fosse esquecida. O
efeito, em bases de código grandes, foram camadas de `catch (Exception e) {}` escritas para o
compilador parar de perguntar, que esquecem todas as falhas de uma vez. **A visão do Kotlin é que uma
falha que o chamador precisa tratar deve estar no tipo de retorno**, como o `Parsed` da aula 9 e o
`Result` da seção 06, e que exceções são para as falhas que um chamador não tem como tratar ali mesmo.

## `throw` é uma expressão

A aula 3 mostrou que `throw` tem o tipo `Nothing`, então ele cabe onde se espera um valor:
`val minutes = text.toIntOrNull() ?: throw IllegalArgumentException("not a number: $text")`. Essa é a
forma comum: **transformar um valor ausente ou errado numa exceção, com mensagem, na linha onde se sabe
pela primeira vez que ele está errado**.
