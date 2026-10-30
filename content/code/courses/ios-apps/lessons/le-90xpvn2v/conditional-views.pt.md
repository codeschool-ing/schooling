---
title: Um if num body é um ramo num tipo
version: 1
---

**Quando um body diz `if done { … } else { … }`, o tipo dele guarda os dois ramos, e qual deles
aparece é um valor lá dentro.** Por isso o SwiftUI sabe, quando `done` vira, que um ramo foi embora e
o outro chegou, e os trata como duas views diferentes: a que saiu é removida com todo estado que
tinha, e a que chegou começa do zero. Isso se chama **identidade estrutural**, identidade dada pela
posição de uma view no tipo, e a aula 8 põe ao lado dela o outro tipo, a identidade explícita vinda de
um `id`.

O builder da seção 06 juntava strings, então perdia o formato. Este guarda o formato no tipo, do jeito
que o do SwiftUI faz. Salve-o como `branches.swift` em `~/l03`:

```schooling-example
{"language": "swift", "file": "branches.swift", "parts": [{"code": "// branches.swift: a builder that keeps the shape in the type, as SwiftUI's does\nstruct Text { let words: String }\nstruct Image { let name: String }\nstruct Pair<A, B> { let first: A; let second: B }\nenum Either<First, Second> { case first(First), second(Second) }\n", "note": "Dois substitutos de view, e dois tipos genéricos para formatos: `Pair` guarda duas coisas lado a lado, e `Either` guarda uma de duas, dizendo qual."}, {"code": "@resultBuilder\nenum ShapeBuilder {\n    static func buildBlock<A>(_ a: A) -> A { a }\n    static func buildBlock<A, B>(_ a: A, _ b: B) -> Pair<A, B> { Pair(first: a, second: b) }\n    static func buildEither<F, S>(first: F) -> Either<F, S> { .first(first) }\n    static func buildEither<F, S>(second: S) -> Either<F, S> { .second(second) }\n}\n", "note": "O builder é genérico, então o tipo de cada resultado é montado a partir dos tipos das partes. Um `if`/`else` vira um `Either` dos tipos dos dois ramos, qualquer que seja o ramo que roda."}, {"code": "func row(done: Bool) -> some Any {\n    func build<T>(@ShapeBuilder _ content: () -> T) -> T { content() }\n    return build {\n        Text(words: \"SQL Databases\")\n        if done {\n            Image(name: \"checkmark\")\n        } else {\n            Text(words: \"50 min\")\n        }\n    }\n}\n", "note": "Uma linha para um curso: o título, depois um sinal de concluído se o trabalho do curso está feito e os minutos se não está. O `some Any` é a regra da seção 03 de novo, um tipo escondido, e compila porque o builder fez um só."}, {"code": "print(type(of: row(done: true)))\nprint(type(of: row(done: false)))\nprint(row(done: true))\nprint(row(done: false))\n", "note": "O tipo das duas linhas, depois os dois valores."}]}
```

```
ana@vm:~/l03$ swift branches.swift
Pair<Text, Either<Image, Text>>
Pair<Text, Either<Image, Text>>
Pair<Text, Either<Image, Text>>(first: branches.Text(words: "SQL Databases"), second: branches.Either<branches.Image, branches.Text>.first(branches.Image(name: "checkmark")))
Pair<Text, Either<Image, Text>>(first: branches.Text(words: "SQL Databases"), second: branches.Either<branches.Image, branches.Text>.second(branches.Text(words: "50 min")))
```

**Os dois tipos são o mesmo, `Pair<Text, Either<Image, Text>>`, e os valores diferem numa palavra:
`.first` contra `.second`.** É tudo de que o SwiftUI precisa para ver que o título ficou onde estava e
que a segunda vaga mudou de ramo. O título mantém a identidade; o sinal de concluído e os minutos são
duas views diferentes em duas vagas diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-branches\" aria-label=\"O tipo Pair&lt;Text, Either&lt;Image, Text&gt;&gt; desenhado como árvore. Pair tem duas vagas: a primeira guarda Text, o título; a segunda guarda Either, que tem dois ramos, first com Image, o sinal de concluído, e second com Text, os minutos. Quando done é verdadeiro o primeiro ramo é preenchido; quando é falso, o segundo. O título fica na mesma vaga nos dois casos.\"><defs><marker id=\"l03-branches-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l03-branches-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-branches-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l03-branches-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"20\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Pair</text><rect x=\"110\" y=\"100\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Text</text><text x=\"200\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o título, sempre aqui</text><rect x=\"430\" y=\"100\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Either</text><path d=\"M330 54 L220 98\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-wire)\"></path><path d=\"M390 54 L490 98\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-wire)\"></path><rect x=\"340\" y=\"180\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.first: Image</text><text x=\"420\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quando done é verdadeiro</text><rect x=\"530\" y=\"180\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.second: Text</text><text x=\"615\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quando done é falso</text><path d=\"M490 134 L430 178\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-amber)\"></path><path d=\"M530 134 L600 178\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-amber)\"></path></svg>", "caption": "Os dois valores têm este tipo único. Virar done leva a segunda vaga de um ramo para o outro, e a view ali é outra view."}
```

## A armadilha que isso arma

Como um ramo é uma view diferente, **virar um `if` zera o que o ramo guardava.** Suponha que a
`CourseDetailView` mostrasse um campo de texto para uma anotação num ramo e o mesmo campo, com outra
cor, no outro. Digitar meia anotação e virar a condição destruiria o campo e criaria um novo, e a meia
anotação sumiria. Quando só um valor difere entre dois ramos, a correção é uma view com um valor que
muda em vez de duas views: um campo cuja cor depende de `done`. A aula 5 encontra a mesma armadilha na
forma de um modificador embrulhado num `if`, e a aula 11 vê o que ela faz com uma animação.

Nada nesta seção rodou o SwiftUI. O programa acima rodou no Linux, e a afirmação de que o SwiftUI trata
os ramos de um `if` como views diferentes vem da sessão *Demystify SwiftUI* da WWDC21 da Apple, que
trata exatamente disso.
