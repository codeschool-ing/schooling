---
title: Dois tipos onde o Java tem um
version: 1
---

Em Java, qualquer variável de tipo objeto pode guardar `null`, e nada no tipo diz se pode. O
compilador aceita `name.length()` seja lá o que `name` guarde, e o programa descobre em tempo de
execução, com um `NullPointerException`. No Android essa exceção é o crash mais comum que existe, e
já era muito antes do Kotlin. **A resposta do Kotlin é partir cada tipo em dois**: `String`, que
nunca guarda `null`, e `String?`, que guarda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-two-types\" aria-label=\"Duas caixas. A da esquerda, String, contém strings como &quot;Kotlin&quot;, &quot;&quot; e &quot;read chapter 3&quot;. A da direita, String?, contém as mesmas strings e também null. Uma seta de String para String? diz livre: toda String é uma String?. Uma seta de volta, de String? para String, diz: precisa de uma resposta para null, com as quatro respostas ?., ?:, if != null e !!.\"><defs><marker id=\"l02-two-types-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-types-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">String</text><text x=\"145\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Kotlin\"</text><text x=\"145\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"\"</text><text x=\"145\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"read chapter 3\"</text><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca null</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">String?</text><rect x=\"480\" y=\"78\" width=\"190\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Kotlin\"</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"\"</text><text x=\"575\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"read chapter 3\"</text><text x=\"575\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">null</text><path d=\"M262 100 L456 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-two-types-ah-phosphor)\"></path><text x=\"359\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">livre: toda String é uma String?</text><path d=\"M456 150 L262 150\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-two-types-ah-amber)\"></path><text x=\"359\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precisa de uma resposta para null</text><text x=\"359\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?.   ?:   if (x != null)   !!</text><text x=\"360\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Os dois tipos do Kotlin: o compilador sabe qual deles um valor tem</text></svg>", "caption": "Toda String é uma String?, então um sentido é livre. O caminho de volta precisa de uma resposta para null, e o Kotlin tem quatro."}
```

O planejador tem um valor de cada tipo. Toda sessão de estudo pertence a um curso, então o nome do
curso sempre existe; uma anotação na sessão é opcional, então ela pode faltar:

```kotlin
// Nulls.kt
fun main() {
    val course: String = "Kotlin"
    val note: String? = null
    println(course.length)
    println(note)
}
```

```
ana@vm:~/kt/l02$ kotlinc Nulls.kt -include-runtime -d nulls.jar && java -jar nulls.jar
6
null
```

O `println(note)` imprimiu a palavra `null`, e tudo bem: imprimir um valor ausente não é erro. O que
os dois tipos mudam é o que o compilador deixa você **fazer** com cada um.

## As duas recusas

Ponha `null` numa `String`, e o programa não compila:

```kotlin
// NullAssign.kt
fun main() {
    val course: String = null
    println(course)
}
```

```
ana@vm:~/kt/l02$ kotlinc NullAssign.kt -include-runtime -d nullassign.jar
NullAssign.kt:3:26: error: null cannot be a value of a non-null type 'String'.
    val course: String = null
                         ^^^^
```

E peça direto o comprimento de uma `String?`, e o compilador também recusa, porque o valor a quem ele
perguntaria pode não estar lá:

```kotlin
// NoteLength.kt
fun main() {
    val note: String? = "read chapter 3"
    println(note.length)
}
```

```
ana@vm:~/kt/l02$ kotlinc NoteLength.kt -include-runtime -d notelength.jar
NoteLength.kt:4:17: error: only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'String?'.
    println(note.length)
                ^
```

Repare no que a segunda recusa diz, porque é o cardápio do resto desta lição: **só chamadas seguras
(`?.`) ou com afirmação de não nulo (`!!.`) são permitidas**. A anotação neste programa nem está
faltando. O compilador recusa mesmo assim, porque o tipo diz que ela poderia faltar, e um tipo é uma
promessa sobre todo valor, não sobre este.

## Um sentido é livre

Toda `String` também é uma `String?`, então uma `String` entra numa `String?` sem nada escrito:
`val maybe: String? = course` compila. O outro sentido, de `String?` para `String`, é o que precisa
de uma resposta para a pergunta "e se for null?". O Kotlin dá quatro jeitos de responder, e cada
seção a seguir é um deles:

| você escreve | significa | seção |
|---|---|---|
| `note?.length` | se `note` for null, a expressão inteira é null | 03 |
| `note ?: "none"` | se `note` for null, use isto no lugar | 04 |
| `if (note != null) note.length` | dentro da verificação, `note` é uma `String` | 05 |
| `note!!.length` | prometo que não é null, e quebre se eu estiver errado | 06 |

Os três primeiros tratam o caso ausente. O quarto devolve o crash. A seção 07 mostra onde a proteção
termina, que é a linha em que o Kotlin chama o Java.
