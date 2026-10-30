---
title: Uma sealed class: um conjunto fixo de formas
version: 1
---

Um enum é um conjunto fixo de valores. **Uma sealed class é um conjunto fixo de tipos**, cada um capaz
de carregar dados próprios. As subclasses dela precisam ser declaradas no mesmo pacote e módulo, então
o compilador vê cada uma, e ninguém acrescenta outra de fora.

```schooling-example
{"language": "kotlin", "file": "Sealed.kt", "parts": [{"code": "sealed class Session {\n    data class Planned(val course: String, val minutes: Int) : Session()\n    data class Running(val course: String, val startedAt: String) : Session()\n    data class Done(val course: String, val minutes: Int) : Session()\n}", "note": "Três formas de sessão, cada uma uma data class com exatamente os dados que aquela forma tem. `: Session()` torna cada uma subclasse da sealed class; a lição 11 cobre herança direito."}, {"code": "fun describe(s: Session): String = when (s) {\n    is Session.Planned -> \"${s.course}: ${s.minutes} min planned\"\n    is Session.Running -> \"${s.course}: running since ${s.startedAt}\"\n    is Session.Done -> \"${s.course}: ${s.minutes} min done\"\n}", "note": "Um ramo por subclasse, sem `else`, e cada ramo faz smart cast: `s.startedAt` só existe no ramo `Running`, porque só uma sessão em andamento tem hora de início."}, {"code": "fun main() {\n    val week = listOf(\n        Session.Done(\"Kotlin\", 45),\n        Session.Running(\"Android\", \"14:30\"),\n        Session.Planned(\"Kotlin\", 30),\n    )\n    week.forEach { println(describe(it)) }\n}"}]}
```

```
ana@vm:~/kt/l09$ kotlinc Sealed.kt -include-runtime -d sealed.jar && java -jar sealed.jar
Kotlin: 45 min done
Android: running since 14:30
Kotlin: 30 min planned
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-sealed\" aria-label=\"Uma sealed class Session no alto, com três subclasses abaixo: Planned, Running e Done, cada uma com os próprios campos. Abaixo delas, uma expressão when com um ramo por subclasse, cada ramo ligado à sua subclasse, então todo caso está coberto e nenhum else é preciso. À direita, uma quarta subclasse, Skipped, tracejada: acrescentada depois, ela não tem ramo, e todo when sem ela para de compilar.\"><defs><marker id=\"l09-sealed-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-sealed-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"230\" y=\"18\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">sealed class Session</text><rect x=\"30\" y=\"90\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Planned</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">course, minutes</text><path d=\"M330 54 L120 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"230\" y=\"90\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Running</text><text x=\"320\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">course, startedAt</text><path d=\"M330 54 L320 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"430\" y=\"90\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Done</text><text x=\"520\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">course, minutes</text><path d=\"M330 54 L520 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30\" y=\"200\" width=\"580\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">when (s) {</text><text x=\"120\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">is Planned -&gt;</text><path d=\"M120 198 L120 144\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-sealed-ah-amber)\"></path><text x=\"320\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">is Running -&gt;</text><path d=\"M320 198 L320 144\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-sealed-ah-amber)\"></path><text x=\"520\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">is Done -&gt;</text><path d=\"M520 198 L520 144\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-sealed-ah-amber)\"></path><rect x=\"630\" y=\"90\" width=\"80\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"670\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Skipped</text><text x=\"670\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">nova</text><text x=\"560\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">sem ramo para Skipped: todo when assim para de compilar</text></svg>", "caption": "Toda subclasse é conhecida, então um when com um ramo para cada uma dispensa o else, e uma subclasse nova quebra todo when que não a tem."}
```

## O que o compilador sabe

`describe` não tem `else`, e o compilador aceita, porque **os três ramos `is` são todas as `Session`
possíveis**. É o mesmo conhecimento que ele tinha sobre os valores do enum, agora sobre tipos.

Compare com a data class da lição 8 com um campo de status: `Session(course, minutes, status,
startedAt: String?)`. Uma sessão planejada carregaria um `startedAt` `null`, os `minutes` de uma
sessão em andamento não significariam nada, e toda função teria de lembrar quais campos fazem sentido
para qual status. **Na versão selada cada forma tem os campos de que precisa e nenhum outro**, e o
compilador verifica que o código que pede `startedAt` está num ramo em que ele existe.

## `is` verifica um tipo; nada é uma string

Os ramos testam tipos. Não há string de status para errar a grafia, nem `ordinal` para salvar, nem
jeito de montar um `Running` sem hora de início. Uma sessão é uma de três coisas, e o tipo dela diz
qual.
