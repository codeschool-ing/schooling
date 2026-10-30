---
title: copy, e mudar um valor sem mudá-lo
version: 1
---

As propriedades de uma sessão são `val`, então marcá-la como feita não pode ser `s.done = true`. **O
`copy` cria uma sessão nova com todas as propriedades iguais, menos as que você nomear**, e deixa a
original intocada:

```kotlin
// Copy.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val planned = Session("Kotlin", 45)
    val finished = planned.copy(done = true)
    val longer = planned.copy(minutes = 60)
    println(planned)
    println(finished)
    println(longer)
}
```

```
ana@vm:~/kt/l08$ kotlinc Copy.kt -include-runtime -d copy.jar && java -jar copy.jar
Session(course=Kotlin, minutes=45, done=false)
Session(course=Kotlin, minutes=45, done=true)
Session(course=Kotlin, minutes=60, done=false)
```

O `copy` tem um parâmetro por propriedade, cada um com o valor atual como padrão, então uma chamada
nomeia só o que muda: os argumentos nomeados e padrão da aula 3 fazendo exatamente aquilo para que
foram feitos.

## Por que não um `var`

Um `var done` deixaria qualquer código que segure uma sessão mudá-la, e todo outro dono veria a
mudança sem ser avisado. **Com `val` e `copy`, uma sessão que alguém lhe deu não muda debaixo de
você**; uma sessão mudada é um objeto novo, e quem precisa dele tem de recebê-lo. A aula 17 se apoia
nisso: o estado de um app é uma data class, toda mudança é um `copy`, e a tela se redesenha quando
recebe um valor novo. Isso só funciona porque o valor antigo nunca mudou.

## Uma cópia é rasa

O `copy` copia as propriedades, e **uma propriedade que se refere a um objeto é copiada como
referência**: a data class nova aponta para o mesmo objeto que a antiga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-shallow\" aria-label=\"Dois objetos de data class, w44 com label week 44 e w45 com label week 45, feitos com copy. Cada um tem o próprio label, mas a propriedade minutes dos dois aponta com uma seta para a mesma MutableList, com 45, 30 e 60. Acrescentar à lista por w45 portanto aparece por w44.\"><defs><marker id=\"l08-shallow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">w44</text><text x=\"150\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label = \"week 44\"</text><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">minutes =</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">w45 = w44.copy(…)</text><text x=\"150\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label = \"week 45\"</text><text x=\"150\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">minutes =</text><path d=\"M262 92 C 350 92 350 118 450 118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-shallow-ah-amber)\"></path><path d=\"M262 192 C 350 192 350 128 450 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-shallow-ah-amber)\"></path><rect x=\"452\" y=\"84\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"567\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">MutableList&lt;Int&gt;</text><text x=\"567\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[45, 30, 60]</text><text x=\"567\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma lista, dois donos</text></svg>", "caption": "O copy copia a referência à lista, não a lista: as duas semanas seguram a mesma."}
```

```kotlin
// Shallow.kt
data class Week(val label: String, val minutes: MutableList<Int>)

fun main() {
    val w44 = Week("week 44", mutableListOf(45, 30))
    val w45 = w44.copy(label = "week 45")
    w45.minutes.add(60)
    println(w44)
    println(w45)
}
```

```
ana@vm:~/kt/l08$ kotlinc Shallow.kt -include-runtime -d shallow.jar && java -jar shallow.jar
Week(label=week 44, minutes=[45, 30, 60])
Week(label=week 45, minutes=[45, 30, 60])
```

A semana 44 ganhou uma sessão de 60 minutos que só foi acrescentada à semana 45, porque as duas
semanas seguram a mesma lista. **A solução é manter data classes feitas de valores que não mudam**:
uma `List`, não uma `MutableList`, de modo que o único caminho para uma lista diferente seja criar uma,
e a cópia não possa ser alterada no lugar. Coisas mutáveis dentro de uma data class fazem `copy`,
`equals` e `hashCode` dependerem todos de um estado que se mexe.
