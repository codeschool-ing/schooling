---
title: Protocolos pequenos, compostos
version: 1
---

**O desenho orientado a protocolo descreve cada capacidade como um protocolo pequeno, e deixa um tipo
conformar a cada uma que tem.** Um tipo que toma tempo conforma a `Timed`; um com nota conforma a
`Graded`; um simulado conforma aos dois, e nada de uma capacidade é copiado para a outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-tree\" aria-label=\"À esquerda, uma árvore de classes: StudyItem no alto, StudySession e Exam abaixo, e MockExam só debaixo de Exam. Uma seta tracejada mostra length copiado de StudySession para MockExam, e uma nota sob MockExam diz minutes vale 0, herdado. À direita, uma grade: três protocolos, Titled, Timed e Graded, como colunas, e StudySession, Exam e MockExam como linhas, com uma marca onde o tipo conforma. MockExam tem as três marcas.\"><defs><marker id=\"l10-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma superclasse cada</text><rect x=\"105\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudyItem</text><rect x=\"25\" y=\"124\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><rect x=\"195\" y=\"124\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Exam</text><rect x=\"195\" y=\"204\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">MockExam</text><path d=\"M175 76 L95 124\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M175 76 L265 124\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M265 156 L265 204\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M95 156 L95 220 L193 220\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-tree-ah-amber)\" stroke-dasharray=\"5 4\"></path><text x=\"95\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">length, copiado</text><text x=\"265\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">minutes: 0, herdado</text><path d=\"M372 20 L372 270\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">um protocolo por capacidade</text><text x=\"520\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Titled</text><text x=\"590\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Timed</text><text x=\"660\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Graded</text><text x=\"392\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><circle cx=\"520\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"660\" cy=\"110\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"392\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Exam</text><circle cx=\"520\" cy=\"155\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"155\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><circle cx=\"660\" cy=\"155\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"392\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">MockExam</text><circle cx=\"520\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"660\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "Na árvore, um simulado fica sob um pai e copia o outro. Na grade, ele lista as capacidades que tem, e cada uma é verificada."}
```

```swift
// Composed.swift
protocol Titled { var title: String { get } }
protocol Timed { var minutes: Int { get } }
protocol Graded { var grade: Int { get } }

struct StudySession: Titled, Timed {
    var title: String
    var minutes: Int
}

struct Exam: Titled, Graded {
    var title: String
    var grade: Int
}

struct MockExam: Titled, Timed, Graded {
    var title: String
    var minutes: Int
    var grade: Int
}

func totalMinutes(_ items: [any Timed]) -> Int {
    items.reduce(0) { $0 + $1.minutes }
}

func report(_ item: some Titled & Graded) -> String {
    "\(item.title): \(item.grade)%"
}

let timed: [any Timed] = [
    StudySession(title: "Optionals", minutes: 45),
    MockExam(title: "Generics", minutes: 60, grade: 70),
]
print("minutes this week:", totalMinutes(timed))
print(report(Exam(title: "Swift basics", grade: 80)))
print(report(MockExam(title: "Generics", minutes: 60, grade: 70)))
```

```
ana@vm:~/sw/l10$ swift Composed.swift
minutes this week: 105
Swift basics: 80%
Generics: 70%
```

O total é 105, e os minutos do simulado contaram. Compare as partes com a seção 02:

- **Nada responde pelo que não tem.** `Exam` não é `Timed`, então não pode ir para `timed` por
  engano, e não há `0` minutos para herdar. Uma prova naquele array é erro de compilação, que é
  exatamente onde o total errado deveria estar.
- **`MockExam` lista o que é**, e o compilador cobra tudo. Deixar `minutes` de fora daria o "does not
  conform" da lição 8, não um zero silencioso.
- **Os tipos são structs.** Nenhum `init` precisou chamar `super.init`, e cada valor ganha o
  inicializador por membros da lição 6 e a semântica de valor da lição 5.

## &: um tipo que é várias coisas

`Titled & Graded` é uma **composição de protocolos**: um tipo que conforma aos dois. O `report` recebe
`some Titled & Graded`, o atalho genérico da lição 9, então aceita um `Exam` e um `MockExam` e recusa
uma `StudySession`. Uma composição usada com frequência pode ganhar nome, `typealias Assessed = Titled
& Graded`, e a biblioteca padrão faz o mesmo: `Codable`, assunto da lição 13, é `Encodable &
Decodable`.

## Pequeno quer dizer pequeno

Um protocolo com um requisito parece burocracia, e é o contrário. **Quanto menos requisitos um
protocolo tem, mais tipos conseguem conformar a ele honestamente**, e mais funções conseguem pedir
exatamente o que usam. O `totalMinutes` precisa de minutos e de nada mais, então pede `Timed` e nada
mais. Um único protocolo `StudyItem` com `minutes`, `grade` e `title` seria de novo a classe base da
seção 02, com os mesmos palpites.
