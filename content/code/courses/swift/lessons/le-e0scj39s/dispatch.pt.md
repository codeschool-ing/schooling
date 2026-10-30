---
title: Qual corpo roda
version: 1
---

A seção 05 terminou numa regra: ponha um membro no protocolo se um tipo que conforma puder
substituí-lo. Esta seção é o porquê. **A mesma chamada no mesmo valor pode rodar dois corpos
diferentes**, dependendo do tipo com que o código o guarda, e nada na chamada mostra isso.

```swift
// Dispatch.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

extension Describable {
    func summary() -> String { "\(title) (no details)" }
    func headline() -> String { "== \(title) ==" }
}

struct Course: Describable {
    var title: String
    func summary() -> String { "\(title): 20 lessons" }
    func headline() -> String { "** \(title) **" }
}

let swift = Course(title: "Swift")
print(swift.summary(), "|", swift.headline())

let item: any Describable = swift
print(item.summary(), "|", item.headline())
```

```
ana@vm:~/sw/l08$ swift Dispatch.swift
Swift: 20 lessons | ** Swift **
Swift: 20 lessons | == Swift ==
```

A primeira linha é o que qualquer um esperaria: `Course` escreveu os dois métodos e os corpos dele
rodaram. A segunda linha é o mesmo valor, guardado como `any Describable`, e **`headline()` rodou o
corpo da extensão, não o da struct**. `summary()` não mudou.

## Requisitos são consultados, extensões não

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l08-dispatch\" aria-label=\"Duas chamadas no mesmo valor guardado como any Describable. item.summary() passa pela tabela de conformidade que Course preencheu e chega ao summary do próprio Course. item.headline() não tem entrada na tabela, então o compilador escolheu o headline da extensão na compilação; o headline do próprio Course, tracejado, não é alcançado pelo protocolo.\"><defs><marker id=\"l08-dispatch-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-dispatch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">item.summary()</text><rect x=\"20\" y=\"170\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">item.headline()</text><rect x=\"270\" y=\"22\" width=\"200\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tabela de conformidade</text><text x=\"370\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">summary() → Course</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course.summary()</text><rect x=\"520\" y=\"105\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Course.headline()</text><text x=\"610\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não alcançado pelo protocolo</text><rect x=\"520\" y=\"175\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">extension headline()</text><path d=\"M220 58 L268 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-phosphor)\"></path><path d=\"M470 58 L518 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-phosphor)\"></path><path d=\"M220 190 L518 193\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-amber)\"></path><text x=\"370\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">consultada enquanto o programa roda</text><text x=\"370\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">escolhido na compilação</text></svg>", "caption": "Um requisito é achado na tabela que cada conformidade preenche. Um método que só existe na extensão é escolhido pelo tipo que o código enxerga."}
```

`summary()` é um **requisito**. Todo tipo que conforma a `Describable` registra qual corpo cumpre cada
requisito, numa tabela que o compilador monta para aquela conformidade, e uma chamada por
`any Describable` consulta o corpo nessa tabela enquanto o programa roda. Então a chamada acha o
método de `Course`, e só acharia um padrão para um tipo que não escreveu nenhum.

`headline()` **não é requisito**; ele só existe na extensão. Uma chamada por `any Describable` não tem
entrada de tabela para consultar, então o compilador decide na compilação, a partir do tipo que
enxerga, que é o protocolo. O `headline()` da struct é outro método que por acaso tem o mesmo nome, e
só é alcançado quando o código guarda um `Course`. O primeiro caso se chama **despacho dinâmico** e o
segundo **despacho estático**.

## Evitando a surpresa

Nada está errado na linguagem aqui; o programa faz o que as declarações dizem. O defeito está num
projeto em que um tipo pretende personalizar um membro que o protocolo nunca pediu. Dois hábitos o
eliminam:

- **todo membro de que um tipo pode escrever sua própria versão vai no protocolo**, com o padrão na
  extensão;
- um membro só na extensão é um **auxiliar** construído a partir dos requisitos, e nenhum tipo que
  conforma deve declarar um com o mesmo nome.

A aula 10 constrói projetos inteiros com extensões de protocolo, e esta regra é o que os mantém
previsíveis.
