---
title: Extensões de protocolo como mixins
version: 1
---

A seção 03 dividiu o planner em capacidades. A outra metade do desenho é onde mora o comportamento.
**Uma extensão de protocolo prende comportamento a uma capacidade, então todo tipo que tem a
capacidade ganha o comportamento**, sem classe base e sem cópia. Uma extensão assim muitas vezes é
chamada de **mixin**: um pacote de métodos misturado a quaisquer tipos que conformem.

```schooling-example
{"language": "swift", "file": "Mixins.swift", "parts": [{"code": "// Mixins.swift\nprotocol Titled { var title: String { get } }\nprotocol Timed { var minutes: Int { get } }", "note": "Duas capacidades, um requisito cada. Uma não sabe nada da outra."}, {"code": "extension Timed {\n    var asHours: String {\n        minutes % 60 == 0 ? \"\\(minutes / 60)h\" : \"\\(minutes / 60)h\\(minutes % 60)\"\n    }\n    var isLong: Bool { minutes >= 60 }\n}", "note": "Comportamento para tudo que tem tempo, montado só com `minutes`. São auxiliares, não requisitos, então nenhum tipo deveria escrever os seus (lição 8, seção 07)."}, {"code": "extension Titled where Self: Timed {\n    var label: String { \"\\(title) (\\(asHours))\" }\n}", "note": "Um membro que só existe em tipos com as duas capacidades: ele precisa de um título e das horas da extensão acima."}, {"code": "extension Sequence where Element: Timed {\n    var totalMinutes: Int { reduce(0) { $0 + $1.minutes } }\n}", "note": "Qualquer sequência de valores com tempo ganha um total: um array, um conjunto, um filtro preguiçoso. A restrição é no elemento, como na lição 9."}, {"code": "struct StudySession: Titled, Timed {\n    var title: String\n    var minutes: Int\n}\n\nstruct Break: Timed {\n    var minutes: Int\n}", "note": "Os dois tipos escrevem suas propriedades armazenadas e mais nada. Uma pausa toma tempo e não tem título, então não tem `label`."}, {"code": "let week = [StudySession(title: \"Optionals\", minutes: 45),\n            StudySession(title: \"Generics\", minutes: 90)]\nfor session in week { print(session.label, session.isLong) }\nprint(week.totalMinutes, week.totalMinutes >= 300 ? \"goal met\" : \"goal not met\")\nprint(Break(minutes: 40).asHours)", "note": "Todo membro usado aqui veio de uma extensão."}], "output": "Optionals (0h45) false\nGenerics (1h30) true\n135 goal not met\n0h40"}
```

O `swift Mixins.swift` o roda. Cada sessão imprimiu o rótulo e se é longa, a semana deu 135 minutos
contra uma meta de 300, e a pausa, que não tem título, ainda sabia as horas dela.

## O comportamento segue a capacidade

As duas structs somam três propriedades armazenadas. Todo o resto, quatro membros, chegou porque elas
conformam a protocolos pequenos com extensões por trás. Acrescente um terceiro tipo com tempo, uma
`Lecture`, e ele tem `asHours`, `isLong` e lugar no `totalMinutes` no momento em que declara
`: Timed`. **Nada foi herdado e nada foi copiado**: o comportamento é escrito uma vez, ao lado da
capacidade de que depende.

## Comportamento condicional

O `label` é o interessante. Ele vive em `extension Titled where Self: Timed`, então só existe num tipo
quando o tipo tem as duas capacidades. Numa árvore de classes isso exigiria uma classe filha de
`Titled` e de `Timed`, a herança dupla que a seção 02 não podia ter. Aqui é uma cláusula `where`. O
`totalMinutes` também é condicional, no elemento de uma sequência, e as restrições da lição 9 são o
que o fazem soar como uma propriedade da semana.

## O limite

Um mixin só pode usar o que o protocolo exige, como a lição 8 disse dos padrões. **Se uma extensão
começa a precisar de uma propriedade que nenhum requisito promete, falta um requisito à capacidade,
ou o membro pertence a um tipo e não ao protocolo.** Essa pergunta, feita toda vez, é o que mantém os
protocolos pequenos.
