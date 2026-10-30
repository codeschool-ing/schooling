---
title: Companion objects: o que pertence à classe, não a uma instância
version: 1
---

O Kotlin não tem `static`. **O que o Java declara estático, o Kotlin põe num `companion object`**: um
objeto declarado dentro de uma classe, alcançado pelo nome da classe, e com permissão para ver os
membros privados dela. A aula 7 deixou o `parseSession` como uma função solta e prometeu uma casa
para ele; é esta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l10-companion\" aria-label=\"À esquerda, a classe Session, contendo o seu único companion object, que guarda MAX_MINUTES, o contador created e as funções of e parse. À direita, três instâncias de Session, cada uma com o próprio curso e minutos. Setas da função of do companion para cada instância: toda instância foi montada por ela. O companion existe uma vez por classe; as instâncias, tantas quantas forem as sessões.\"><defs><marker id=\"l10-companion-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">class Session</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">companion object</text><text x=\"170\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MAX_MINUTES = 600</text><text x=\"170\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">created = 2</text><text x=\"170\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fun of(…)</text><text x=\"170\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fun parse(…)</text><text x=\"170\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um por classe</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Kotlin\", 45</text><path d=\"M300 150 L468 55\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><rect x=\"470\" y=\"96\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Android\", 30</text><path d=\"M300 150 L468 121\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><rect x=\"470\" y=\"162\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Kotlin\", 60</text><path d=\"M300 150 L468 187\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><text x=\"585\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma por sessão</text></svg>", "caption": "Um companion object para a classe, quantas instâncias ela montar."}
```

```schooling-example
{"language": "kotlin", "file": "Companion.kt", "parts": [{"code": "class Session private constructor(val course: String, val minutes: Int) {", "note": "`private constructor`: nada fora da classe chama `Session(…)`. Os únicos caminhos de entrada são as funções do companion."}, {"code": "    companion object {\n        const val MAX_MINUTES = 600\n        private var created = 0", "note": "Um companion por classe, quantas sessões existirem. `const val` é uma constante de compilação, seção 04. `created` é dividido pela classe inteira."}, {"code": "        fun of(course: String, minutes: Int): Session? {\n            if (minutes !in 1..MAX_MINUTES) return null\n            created++\n            return Session(course, minutes)\n        }", "note": "Uma fábrica: ela chama o construtor privado porque está dentro da classe, e pode recusar devolvendo `null`, o que um construtor não faz."}, {"code": "        fun parse(line: String): Session? {\n            val minutes = line.substringAfter(\",\").trim().toIntOrNull() ?: return null\n            return of(line.substringBefore(\",\").trim(), minutes)\n        }", "note": "O interpretador da aula 7, agora dentro da classe que ele monta, e passando pelo `of` para a verificação de faixa morar num lugar só."}, {"code": "        val count: Int\n            get() = created\n    }\n}", "note": "Uma visão somente leitura do contador privado."}, {"code": "fun main() {\n    println(Session.of(\"Kotlin\", 45)?.minutes)\n    println(Session.of(\"Kotlin\", 900))\n    println(Session.parse(\"Android, 30\")?.course)\n    println(Session.count)\n    println(Session.MAX_MINUTES)\n}", "note": "Tudo é chamado pelo nome da classe, como um estático do Java seria."}]}
```

```
ana@vm:~/kt/l10$ kotlinc Companion.kt -include-runtime -d companion.jar && java -jar companion.jar
45
null
Android
2
600
```

Duas sessões foram montadas e uma recusada, e `count` diz 2. Com o construtor privado, **toda sessão
do programa passou pelo `of`**, então a verificação de faixa não é pulada e a contagem não erra. Chame
o construtor de fora e o compilador recusa:

```kotlin
// Direct.kt
class Session private constructor(val course: String, val minutes: Int)

fun main() {
    println(Session("Kotlin", 45).minutes)
}
```

```
ana@vm:~/kt/l10$ kotlinc Direct.kt -include-runtime -d direct.jar
Direct.kt:5:13: error: cannot access 'constructor(course: String, minutes: Int): Session': it is private in 'Session'.
    println(Session("Kotlin", 45).minutes)
            ^^^^^^^
```

## Nomes de fábrica

A biblioteca padrão e o Android usam poucos nomes para fábricas de companion, e segui-los faz uma
classe se ler como o resto do Kotlin: **`of` para montar a partir de partes, `parse` ou `from` para
converter de outra forma**, e `create` quando montar tem um efeito colateral. `listOf`,
`Duration.parse` e `Uri.parse` seguem esse padrão.
