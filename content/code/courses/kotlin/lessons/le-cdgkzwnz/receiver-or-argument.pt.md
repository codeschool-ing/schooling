---
title: Cinco funções, duas perguntas
version: 1
---

`let`, `run`, `with`, `apply` e `also` fazem todas a mesma coisa: **rodam um bloco de código com um
objeto na mão**. É por isso que confundem todo mundo, e por isso vale aprendê-las como conjunto, e não
uma a uma. Duas perguntas as separam, e cada uma tem duas respostas.

1. **Dentro do bloco, como você se refere ao objeto?** Como `it`, um parâmetro da lambda, ou como
   `this`, o receptor do bloco, que pode ser omitido de vez: `sum()` em vez de `it.sum()`.
2. **O que a chamada devolve?** O próprio objeto, ou o que for a última expressão do bloco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-scope\" aria-label=\"Uma grade de dois por dois. Colunas: o objeto é it, um parâmetro; o objeto é this, um receptor. Linhas: a chamada devolve o resultado do bloco; a chamada devolve o objeto. Células: let em it e resultado; run e with em this e resultado; also em it e objeto; apply em this e objeto.\"><defs></defs><text x=\"345\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o objeto é it</text><text x=\"565\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o objeto é this</text><text x=\"130\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">devolve o</text><text x=\"130\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">resultado do bloco</text><text x=\"130\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">devolve o</text><text x=\"130\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">objeto</text><rect x=\"240\" y=\"55\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">let</text><text x=\"345\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x?.let { it.length }</text><rect x=\"460\" y=\"55\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">run   with</text><text x=\"565\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.run { length }</text><rect x=\"240\" y=\"145\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--phosphor)\">also</text><text x=\"345\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.also { log(it) }</text><rect x=\"460\" y=\"145\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--phosphor)\">apply</text><text x=\"565\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.apply { append(\"…\") }</text><text x=\"455\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">duas perguntas: como o objeto se chama lá dentro, e o que volta</text></svg>", "caption": "As cinco funções de escopo em dois eixos: como o bloco nomeia o objeto, e o que a chamada devolve."}
```

Um programa roda as cinco sobre a mesma lista e imprime o que cada uma devolveu:

```kotlin
// Scope.kt
fun main() {
    val sessions = mutableListOf(45, 30)
    val a = sessions.let { it.sum() }
    val b = sessions.run { sum() }
    val c = with(sessions) { sum() }
    val d = sessions.apply { add(60) }
    val e = sessions.also { it.add(20) }
    println("let   $a")
    println("run   $b")
    println("with  $c")
    println("apply $d")
    println("also  $e")
}
```

```
ana@vm:~/kt/l06$ kotlinc Scope.kt -include-runtime -d scope.jar && java -jar scope.jar
let   75
run   75
with  75
apply [45, 30, 60, 20]
also  [45, 30, 60, 20]
```

`let`, `run` e `with` devolveram o resultado do bloco, a soma, e rodaram antes de qualquer coisa ser
acrescentada. `apply` e `also` devolveram **a própria lista**, e é por isso que as duas linhas imprimem
os quatro itens: `d` e `e` são a mesma lista, que na hora de imprimir já tinha recebido 60 do `apply`
e 20 do `also`.

## O que é um receptor

Em `run { sum() }`, o `sum()` é chamado na lista sem nomeá-la. O bloco é uma **lambda com receptor**:
o tipo dela se escreve `MutableList<Int>.() -> Int`, e dentro dela `this` é a lista, assim como dentro
de um método `this` é o objeto. As lambdas da aula 4 tinham parâmetros; este tipo tem um objeto sobre
o qual trabalha, e as funções de extensão da aula 11 são a mesma ideia declarada com nome.

O `buildList { add(45) }` da aula 5 era uma dessas, e também é cada bloco de um script de build do
Gradle na aula 19. **Quando o `this` pode ser omitido, um bloco se lê como uma pequena linguagem para
um objeto**, e esse é o motivo de tudo isso existir.
