---
title: Implementações padrão
version: 1
---

A seção 04 acrescentou membros a um tipo. **Uma extensão de um protocolo acrescenta membros a todo
tipo que conforma a ele**, e quando um desses membros tem o mesmo nome e tipo de um requisito, ele
vira a **implementação padrão**: um tipo que conforma e não escreve nada para aquele requisito fica
com o padrão, e um que escreve o seu fica com o seu.

```schooling-example
{"language": "swift", "file": "Defaults.swift", "parts": [{"code": "// Defaults.swift\nprotocol Timed {\n    var title: String { get }\n    var minutes: Int { get }\n    func summary() -> String\n}", "note": "Duas propriedades e um método. Nada aqui diz como `summary()` é escrito, então todo tipo que conforma teria de escrever um."}, {"code": "extension Timed {\n    func summary() -> String { \"\\(title), \\(minutes) min\" }\n    var isLong: Bool { minutes >= 60 }\n}", "note": "Uma extensão de protocolo. `summary()` ganha um corpo padrão montado só com os dois requisitos, e `isLong` é um membro novo que todo tipo que conforma recebe de graça."}, {"code": "struct StudySession: Timed {\n    var title: String\n    var minutes: Int\n}", "note": "Cumpre as duas propriedades e não escreve `summary()` nenhum: o padrão preenche o requisito."}, {"code": "struct Exam: Timed {\n    var title: String\n    var minutes: Int\n    func summary() -> String { \"EXAM \\(title) (\\(minutes) min)\" }\n}", "note": "Escreve o próprio `summary()`, que substitui o padrão só para este tipo."}, {"code": "let week: [any Timed] = [\n    StudySession(title: \"Optionals\", minutes: 45),\n    Exam(title: \"Swift basics\", minutes: 90),\n]\nfor item in week {\n    print(item.summary(), item.isLong)\n}", "note": "Por meio de `any Timed`, cada elemento responde com o `summary()` do próprio tipo, padrão ou não."}], "output": "Optionals, 45 min false\nEXAM Swift basics (90 min) true"}
```

O `swift Defaults.swift` o roda, e a saída tem duas linhas, uma por elemento. A sessão não tinha
`summary()` próprio e imprimiu no formato do padrão; o exame imprimiu suas maiúsculas. `isLong` nunca
foi declarado em nenhuma das structs, e as duas respondem a ele.

## O que um padrão pode usar

Um padrão é escrito uma vez para tipos que ele nunca viu, então **só pode usar o que o protocolo
garante**: aqui, `title` e `minutes`. Pedir `self.lessons` dentro da extensão não compilaria, porque
nada promete que todo tipo `Timed` tem lições. Essa restrição é o que deixa um bom padrão pequeno:
uma frase montada com os requisitos, uma verificação sobre eles, um cálculo com eles.

## Padrões com condição

Uma extensão pode se limitar a alguns dos tipos que conformam com uma cláusula `where`, como
`extension Timed where Self: Equatable`, e seus membros então só existem nos tipos que cumprem as
duas coisas. A biblioteca padrão usa isso em toda parte: `contains(_:)` só existe num array quando
os elementos são `Equatable`, porque comparar precisa de `==`. A lição 9 escreve restrições desse
tipo para genéricos.

## Requisito ou não

`summary()` está listado no protocolo e `isLong` não. Essa diferença parece contabilidade, e ela
decide qual corpo roda quando um tipo escreve a própria versão, que é a surpresa que a seção 07
desmonta. **A regra para levar agora: se um tipo que conforma pode substituir um membro, liste o
membro no protocolo.**
